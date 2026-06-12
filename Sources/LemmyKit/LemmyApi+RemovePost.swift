//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Remove (or restore) the post `postID` as a moderator or admin.
    ///
    /// Pass `removed: true` to remove the post, `removed: false` to restore
    /// it. An optional `reason` is recorded in the mod log.
    func removePost(
        postID: Components.Schemas.PostID,
        removed: Bool,
        reason: String? = nil
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.removePost.Output
        do {
            response = try await client.removePost(body: .json(.init(
                post_id: postID,
                removed: removed,
                reason: reason
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
