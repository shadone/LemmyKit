//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Remove or restore the comment `commentID` as a moderator or admin.
    ///
    /// - Parameters:
    ///   - commentID: the comment to remove or restore.
    ///   - removed: true to remove the comment, false to restore it.
    ///   - reason: optional reason recorded in the mod log.
    /// - Note: requires moderator or admin.
    func removeComment(
        commentID: Components.Schemas.CommentID,
        removed: Bool,
        reason: String? = nil
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.removeComment.Output
        do {
            response = try await client.removeComment(body: .json(.init(
                comment_id: commentID,
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
