//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Result of a successful pict-rs image upload.
    struct UploadedImage: Sendable, Equatable {
        /// The fully-qualified url where the image can be fetched, e.g.
        /// `https://lemmy.world/pictrs/image/abc123.jpg`. This is what you pass
        /// as a post `url` or embed in markdown.
        public let url: URL
        /// pict-rs delete token, retained so the upload can be undone later.
        public let deleteToken: String
        /// The raw pict-rs file alias (`abc123.jpg`).
        public let file: String
    }

    /// Upload an image to the instance's pict-rs backend.
    ///
    /// This does NOT go through the generated OpenAPI client: pict-rs expects a
    /// `multipart/form-data` body with the field name `images[]` and a filename
    /// in the part's `Content-Disposition`, which is built by hand here for
    /// determinism. The account JWT (same token `AuthorizationMiddleware`
    /// attaches) is sent as a `Bearer` `Authorization` header.
    ///
    /// - Parameters:
    ///   - imageData: the raw image bytes (JPEG/PNG/etc).
    ///   - fileName: a filename for the part, e.g. `upload.jpg`.
    ///   - mimeType: the image MIME type, defaults to `image/jpeg`.
    /// - Returns: the uploaded image url plus its delete token.
    func uploadImage(
        imageData: Data,
        fileName: String,
        mimeType: String = "image/jpeg"
    ) async throws -> UploadedImage {
        guard let jwt = credential?.jwt else {
            throw LemmyApiError.unauthorized(message: "Image upload requires a signed-in account")
        }

        let endpoint = instanceUrl.appendingPathComponent("pictrs/image")

        var form = MultipartFormData()
        form.appendFile(
            name: "images[]",
            fileName: fileName,
            mimeType: mimeType,
            data: imageData
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Same plain agent as the generated client (see UserAgentMiddleware) so
        // an instance's nginx does not 403 the default CFNetwork agent.
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = form.encode()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LemmyApiError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LemmyApiError.unknownServerError(httpStatusCode: -1, error: nil)
        }

        switch httpResponse.statusCode {
        case 200, 201:
            break
        case 401:
            throw LemmyApiError.unauthorized(message: nil)
        default:
            throw LemmyApiError.unknownServerError(httpStatusCode: httpResponse.statusCode, error: nil)
        }

        let uploadResponse: Components.Schemas.ImageUploadResponse
        do {
            uploadResponse = try JSONDecoder().decode(
                Components.Schemas.ImageUploadResponse.self,
                from: data
            )
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }

        guard let image = uploadResponse.files.first else {
            throw LemmyApiError.unknownServerError(httpStatusCode: httpResponse.statusCode, error: nil)
        }

        let imageUrl = instanceUrl
            .appendingPathComponent("pictrs/image")
            .appendingPathComponent(image.file)

        return UploadedImage(
            url: imageUrl,
            deleteToken: image.delete_token,
            file: image.file
        )
    }
}
