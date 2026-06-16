//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List @mentions of the logged-in account across the instance.
    ///
    /// - Parameters:
    ///   - commentSort: mention ordering; when nil, the server's default applies.
    ///   - unreadOnly: when true, return only unread mentions.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of mentions to return.
    /// - Note: requires authentication.
    func getPersonMentions(
        commentSort: Components.Schemas.CommentSortType? = nil,
        unreadOnly: Bool? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPersonMentionsResponse {
        let response: Operations.getPersonMentions.Output
        do {
            response = try await client.getPersonMentions(query: .init(
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
