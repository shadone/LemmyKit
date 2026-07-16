//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import OpenAPIRuntime

public extension LemmyApi {
    /// Sets the signed-in account's avatar from a raw picked image, returning the resulting url.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). The two backends model avatars completely differently, and this method
    /// hides that split so callers only ever hand over the raw image bytes:
    ///
    /// - `.v3` has no avatar endpoint of its own: the image is first uploaded to the instance's
    ///   pict-rs backend (reusing ``uploadImage(imageData:fileName:mimeType:)``) to obtain a url,
    ///   which is then written to the account with `saveUserSettings(avatar:)`. Two round-trips.
    /// - `.v4` posts the raw bytes straight to the dedicated `UploadUserAvatar` endpoint
    ///   (`POST /api/v4/account/avatar`) as a single `image` multipart part -- no settings
    ///   round-trip -- and reads the resulting url out of that endpoint's `UploadImageResponse`.
    ///
    /// - Parameters:
    ///   - imageData: the raw image bytes (JPEG/PNG/etc).
    ///   - fileName: a filename for the upload, e.g. `avatar.jpg`.
    ///   - contentType: the image MIME type, e.g. `image/jpeg`. Used only on `.v3` (as the pict-rs
    ///     upload part's content type); `.v4`'s generated multipart serializer fixes the part to
    ///     `application/octet-stream`, so this value is ignored on a v4 backend.
    /// - Returns: the resulting avatar url -- the synthesized pict-rs url on `.v3`, or the url from
    ///   `UploadUserAvatar`'s response on `.v4`. nil only if a v4 response url fails to parse (a v3
    ///   upload always synthesizes a url).
    /// - Note: requires authentication.
    func setAvatarNeutral(imageData: Data, fileName: String, contentType: String) async throws -> URL? {
        switch apiVersion {
        case .v3:
            try await setAvatarNeutralV3(imageData: imageData, fileName: fileName, contentType: contentType)
        case .v4:
            try await setAvatarNeutralV4(imageData: imageData, fileName: fileName)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "setAvatar")
        }
    }

    /// Clears the signed-in account's avatar.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``).
    ///
    /// - `.v3` clears by writing an empty avatar string through `saveUserSettings(avatar:)`; Lemmy
    ///   v3 treats `Some("")` as "set to null" (an omitted/`nil` field would instead leave the
    ///   current avatar unchanged), which is why the empty string -- not nil -- is what clears it.
    /// - `.v4` calls the dedicated `DeleteUserAvatar` endpoint (`DELETE /api/v4/account/avatar`).
    ///
    /// - Note: requires authentication.
    func removeAvatarNeutral() async throws {
        switch apiVersion {
        case .v3:
            _ = try await saveUserSettings(avatar: "")
        case .v4:
            try await removeAvatarNeutralV4()
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "removeAvatar")
        }
    }

    /// Sets the signed-in account's profile banner from a raw picked image, returning the url.
    ///
    /// The banner counterpart of ``setAvatarNeutral(imageData:fileName:contentType:)`` -- identical
    /// dispatch, targeting the banner instead: `.v3` uploads to pict-rs then writes
    /// `saveUserSettings(banner:)`; `.v4` posts the raw bytes to `UploadUserBanner`
    /// (`POST /api/v4/account/banner`).
    ///
    /// - Parameters:
    ///   - imageData: the raw image bytes (JPEG/PNG/etc).
    ///   - fileName: a filename for the upload, e.g. `banner.jpg`.
    ///   - contentType: the image MIME type, e.g. `image/jpeg`. Used only on `.v3` (as the pict-rs
    ///     upload part's content type); `.v4`'s generated multipart serializer fixes the part to
    ///     `application/octet-stream`, so this value is ignored on a v4 backend.
    /// - Returns: the resulting banner url -- the synthesized pict-rs url on `.v3`, or the url from
    ///   `UploadUserBanner`'s response on `.v4`. nil only if a v4 response url fails to parse (a v3
    ///   upload always synthesizes a url).
    /// - Note: requires authentication.
    func setBannerNeutral(imageData: Data, fileName: String, contentType: String) async throws -> URL? {
        switch apiVersion {
        case .v3:
            try await setBannerNeutralV3(imageData: imageData, fileName: fileName, contentType: contentType)
        case .v4:
            try await setBannerNeutralV4(imageData: imageData, fileName: fileName)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "setBanner")
        }
    }

    /// Clears the signed-in account's profile banner.
    ///
    /// The banner counterpart of ``removeAvatarNeutral()``: `.v3` writes an empty banner string
    /// through `saveUserSettings(banner:)` (an empty string clears, nil would leave it unchanged);
    /// `.v4` calls the dedicated `DeleteUserBanner` endpoint (`DELETE /api/v4/account/banner`).
    ///
    /// - Note: requires authentication.
    func removeBannerNeutral() async throws {
        switch apiVersion {
        case .v3:
            _ = try await saveUserSettings(banner: "")
        case .v4:
            try await removeBannerNeutralV4()
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "removeBanner")
        }
    }
}

private extension LemmyApi {
    /// v3 avatar set: uploads to pict-rs, then writes the resulting url with
    /// `saveUserSettings(avatar:)`, returning that url (`uploadImage` always synthesizes a
    /// non-optional url from the instance base url plus the returned file alias).
    func setAvatarNeutralV3(imageData: Data, fileName: String, contentType: String) async throws -> URL? {
        let uploaded = try await uploadImage(imageData: imageData, fileName: fileName, mimeType: contentType)
        _ = try await saveUserSettings(avatar: uploaded.url.absoluteString)
        return uploaded.url
    }

    /// v3 banner set: the banner twin of `setAvatarNeutralV3`, writing `saveUserSettings(banner:)`.
    func setBannerNeutralV3(imageData: Data, fileName: String, contentType: String) async throws -> URL? {
        let uploaded = try await uploadImage(imageData: imageData, fileName: fileName, mimeType: contentType)
        _ = try await saveUserSettings(banner: uploaded.url.absoluteString)
        return uploaded.url
    }

    /// v4 avatar set: builds the generated client's multipart body by hand -- a single `image`
    /// part wrapping the raw bytes as an `HTTPBody`, with `fileName` carried as the part's
    /// `Content-Disposition` filename (the part's content type is fixed to
    /// `application/octet-stream` by the generated serializer, not this call site) -- posts it to
    /// `UploadUserAvatar`, and parses the returned `{ filename, image_url }`'s url. v4's
    /// `UploadUserAvatar` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func setAvatarNeutralV4(imageData: Data, fileName: String) async throws -> URL? {
        let payload = LemmyKitV4Generated.Operations.UploadUserAvatar.Input.Body.multipartFormPayload
            .imagePayload(body: OpenAPIRuntime.HTTPBody(imageData))
        let part = OpenAPIRuntime.MultipartPart(payload: payload, filename: fileName)
        let body = LemmyKitV4Generated.Operations.UploadUserAvatar.Input.Body.multipartForm([.image(part)])

        let response: LemmyKitV4Generated.Operations.UploadUserAvatar.Output
        do {
            response = try await v4Client.UploadUserAvatar(body: body)
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return URL(string: json.image_url)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 banner set: the banner twin of `setAvatarNeutralV4`, posting to `UploadUserBanner`.
    func setBannerNeutralV4(imageData: Data, fileName: String) async throws -> URL? {
        let payload = LemmyKitV4Generated.Operations.UploadUserBanner.Input.Body.multipartFormPayload
            .imagePayload(body: OpenAPIRuntime.HTTPBody(imageData))
        let part = OpenAPIRuntime.MultipartPart(payload: payload, filename: fileName)
        let body = LemmyKitV4Generated.Operations.UploadUserBanner.Input.Body.multipartForm([.image(part)])

        let response: LemmyKitV4Generated.Operations.UploadUserBanner.Output
        do {
            response = try await v4Client.UploadUserBanner(body: body)
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return URL(string: json.image_url)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 avatar remove: calls the bodyless `DeleteUserAvatar` endpoint. v4's `DeleteUserAvatar`
    /// only documents the `ok` (`SuccessResponse`) response, so anything else falls through to
    /// `.undocumented`; the success payload carries nothing this caller needs.
    func removeAvatarNeutralV4() async throws {
        let response: LemmyKitV4Generated.Operations.DeleteUserAvatar.Output
        do {
            response = try await v4Client.DeleteUserAvatar()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 banner remove: the banner twin of `removeAvatarNeutralV4`, calling `DeleteUserBanner`.
    func removeBannerNeutralV4() async throws {
        let response: LemmyKitV4Generated.Operations.DeleteUserBanner.Output
        do {
            response = try await v4Client.DeleteUserBanner()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
