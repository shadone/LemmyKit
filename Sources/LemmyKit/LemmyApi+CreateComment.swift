//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a new comment on `postID`. Pass `parentID` to reply to an
    /// existing comment, or `nil` to reply to the post itself.
    func createComment(
        postID: Components.Schemas.PostID,
        content: String,
        parentID: Components.Schemas.CommentID? = nil
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.createComment.Output
        do {
            response = try await client.createComment(body: .json(.init(
                content: content,
                post_id: postID,
                parent_id: parentID
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
