//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func getPersonMentions(
        commentSort: Components.Schemas.CommentSortType,
        unreadOnly: Bool,
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
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode)
        }
    }

    @available(*, deprecated)
    func getPersonMentions(
        commentSort: Components.Schemas.CommentSortType,
        unreadOnly: Bool,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) -> AnyPublisher<Components.Schemas.GetPersonMentionsResponse, LemmyApiError> {
        Future {
            try await self.getPersonMentions(
                commentSort: commentSort,
                unreadOnly: unreadOnly,
                page: page,
                limit: limit
            )
        }.eraseToAnyPublisher()
    }
}
