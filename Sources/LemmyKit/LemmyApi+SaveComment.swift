//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Save or unsave a comment for the logged-in account.
    ///
    /// - Parameters:
    ///   - commentID: the comment to save or unsave.
    ///   - save: true to save the comment, false to unsave it.
    /// - Note: requires authentication.
    func saveComment(
        commentID: Components.Schemas.CommentID,
        save: Bool
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.saveComment.Output
        do {
            response = try await client.saveComment(body: .json(.init(
                comment_id: commentID,
                save: save
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
