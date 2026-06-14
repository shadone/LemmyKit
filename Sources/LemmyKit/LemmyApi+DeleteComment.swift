//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Delete or restore a comment identified by `commentID`.
    /// - Parameter deleted: Pass `true` to delete, `false` to restore.
    func deleteComment(
        commentID: Components.Schemas.CommentID,
        deleted: Swift.Bool
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.deleteComment.Output
        do {
            response = try await client.deleteComment(body: .json(.init(
                comment_id: commentID,
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
