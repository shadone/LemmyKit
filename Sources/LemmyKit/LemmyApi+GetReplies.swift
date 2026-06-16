//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List replies to the logged-in account's posts and comments.
    ///
    /// - Parameters:
    ///   - commentSort: reply ordering; when nil, the server's default applies.
    ///   - unreadOnly: when true, return only unread replies.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of replies to return.
    /// - Note: requires authentication.
    func getReplies(
        commentSort: Components.Schemas.CommentSortType? = nil,
        unreadOnly: Bool? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetRepliesResponse {
        let response: Operations.getReplies.Output
        do {
            response = try await client.getReplies(query: .init(
                sort: commentSort,
                unread_only: unreadOnly,
                page: page,
                limit: limit
            ))
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
