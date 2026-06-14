//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Delete (or restore) the post identified by `postID`. Pass `deleted`
    /// to `true` to delete it or `false` to restore it.
    func deletePost(
        postID: Components.Schemas.PostID,
        deleted: Bool
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.deletePost.Output
        do {
            response = try await client.deletePost(body: .json(.init(
                post_id: postID,
                deleted: deleted
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
