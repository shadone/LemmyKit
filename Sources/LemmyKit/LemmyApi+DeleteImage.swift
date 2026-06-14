//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Delete a previously uploaded pict-rs image.
    ///
    /// Unlike most endpoints this is a pict-rs route whose only success
    /// status is `204 No Content`, so there is no response body to return.
    ///
    /// - Parameters:
    ///   - deleteToken: the delete token returned when the image was uploaded,
    ///     proving ownership of the file.
    ///   - fileName: the pict-rs file alias (e.g. `abc123.jpg`) to delete.
    func deleteImage(
        deleteToken: String,
        fileName: String
    ) async throws {
        let response: Operations.deleteImage.Output
        do {
            response = try await client.deleteImage(path: .init(
                delete_token: deleteToken,
                filename: fileName
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .noContent:
            return

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case .forbidden:
            throw LemmyApiError.unknownServerError(httpStatusCode: 403, error: nil)

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
