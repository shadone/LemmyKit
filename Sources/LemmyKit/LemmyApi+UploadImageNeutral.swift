//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import OpenAPIRuntime

public extension LemmyApi {
    /// Uploads an image and returns the version-neutral ``UploadedImage``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). Unlike the other `*Neutral` endpoints, the two backends' upload paths
    /// aren't a thin request/response reshape of the same wire call -- they hit different hosts
    /// with different multipart field names and response shapes:
    ///
    /// - `.v3` uploads to the instance's separate pict-rs backend at `pictrs/image`, with a
    ///   hand-rolled `multipart/form-data` body whose file field is named `images[]` (an array).
    ///   This reuses ``uploadImage(imageData:fileName:mimeType:)`` wholesale -- rather than
    ///   re-implementing that hand-rolled multipart handling -- and maps its result (this
    ///   package's v3-only `LemmyApi.UploadedImage`, disambiguated below as `LemmyKit.
    ///   UploadedImage` since it shares a bare name with this file's neutral type) onto the
    ///   neutral shape.
    /// - `.v4` posts to `/api/v4/image` through the generated client, whose OpenAPI-documented
    ///   multipart body has a single field named `image` (not an array, no instance-supplied
    ///   content type -- the generated serializer fixes it to `application/octet-stream`) and
    ///   returns `{ filename, image_url }` directly, with no separate host and no delete token.
    ///
    /// - Parameters:
    ///   - imageData: the raw image bytes (JPEG/PNG/etc).
    ///   - fileName: a filename for the upload, e.g. `upload.jpg`.
    /// - Returns: the version-neutral ``UploadedImage``.
    /// - Note: requires authentication.
    func uploadImageNeutral(imageData: Data, fileName: String) async throws -> LemmyKit.UploadedImage {
        switch apiVersion {
        case .v3:
            try await uploadImageNeutralV3(imageData: imageData, fileName: fileName)
        case .v4:
            try await uploadImageNeutralV4(imageData: imageData, fileName: fileName)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses ``uploadImage(imageData:fileName:mimeType:)`` -- the existing hand-rolled
    /// pict-rs multipart upload -- wholesale, then maps its result onto the neutral shape. That
    /// method already synthesizes the fully-qualified pict-rs `url` from the instance base url
    /// plus the returned file alias, so `imageURL` here is that synthesized url, not something
    /// read directly off the wire (v3's response carries no url of its own).
    func uploadImageNeutralV3(imageData: Data, fileName: String) async throws -> LemmyKit.UploadedImage {
        let uploaded = try await uploadImage(imageData: imageData, fileName: fileName)

        return LemmyKit.UploadedImage(
            filename: uploaded.file,
            imageURL: uploaded.url,
            deleteToken: uploaded.deleteToken
        )
    }

    /// v4 path: builds the generated client's multipart body by hand -- a single `image` part
    /// wrapping the raw bytes as an `HTTPBody`, with `fileName` carried as the part's
    /// `Content-Disposition` filename; the part's content type is fixed to
    /// `application/octet-stream` by the generated serializer itself (see
    /// `Operations.UploadImage`'s `Client.swift`), not something this call site controls. Calls
    /// the v4 generated client's `UploadImage` operation, then maps the returned
    /// `{ filename, image_url }` onto the neutral shape. v4's `UploadImage` only documents the
    /// `ok` response for this operation (no `unauthorized`/`badRequest` cases like v3), so
    /// anything else falls through to `.undocumented`.
    func uploadImageNeutralV4(imageData: Data, fileName: String) async throws -> LemmyKit.UploadedImage {
        let payload = LemmyKitV4Generated.Operations.UploadImage.Input.Body.multipartFormPayload
            .imagePayload(body: OpenAPIRuntime.HTTPBody(imageData))
        let part = OpenAPIRuntime.MultipartPart(payload: payload, filename: fileName)
        let body = LemmyKitV4Generated.Operations.UploadImage.Input.Body.multipartForm([.image(part)])

        let response: LemmyKitV4Generated.Operations.UploadImage.Output
        do {
            response = try await v4Client.UploadImage(body: body)
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return LemmyKit.UploadedImage(
                    filename: json.filename,
                    imageURL: URL(string: json.image_url),
                    deleteToken: nil
                )
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
