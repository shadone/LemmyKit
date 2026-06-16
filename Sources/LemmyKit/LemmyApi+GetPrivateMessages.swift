//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List the logged-in account's private messages.
    ///
    /// - Parameters:
    ///   - unreadOnly: when true, return only unread messages.
    ///   - creatorID: when provided, return only messages from this sender; nil returns all.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of messages to return.
    /// - Note: requires authentication.
    func getPrivateMessages(
        unreadOnly: Bool? = nil,
        creatorID: Components.Schemas.PersonID? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.PrivateMessagesResponse {
        let response: Operations.getPrivateMessages.Output
        do {
            response = try await client.getPrivateMessages(query: .init(
                unread_only: unreadOnly,
                creator_id: creatorID,
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
