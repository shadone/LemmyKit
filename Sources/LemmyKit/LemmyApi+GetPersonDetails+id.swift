//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Fetch a person by their id.
    func getPersonDetails(
        personId: Components.Schemas.PersonID,
        sort: Components.Parameters.Sort? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPersonDetailsResponse {
        let response: Operations.getPersonDetails.Output
        do {
            response = try await client.getPersonDetails(query: .init(
                person_id: personId,
                sort: sort,
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
    func getPersonDetails(
        personId: Components.Schemas.PersonID,
        sort: Components.Parameters.Sort? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) -> AnyPublisher<Components.Schemas.GetPersonDetailsResponse, LemmyApiError> {
        Future {
            try await self.getPersonDetails(
                personId: personId,
                sort: sort,
                page: page,
                limit: limit
            )
        }.eraseToAnyPublisher()
    }
}
