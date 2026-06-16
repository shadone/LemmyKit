//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Permanently purge a comment and all attached content from the database. This is irreversible.
    ///
    /// - Parameters:
    ///   - commentID: the comment to purge.
    ///   - reason: optional reason recorded in the admin log.
    /// - Note: admin only.
    func purgeComment(
        commentID: Components.Schemas.CommentID,
        reason: String? = nil
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.purgeComment.Output
        do {
            response = try await client.purgeComment(body: .json(.init(
                comment_id: commentID,
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
