//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch a person's profile and activity by their numeric id.
    ///
    /// - Parameters:
    ///   - personID: the person whose details to fetch.
    ///   - sort: sort order for the person's posts and comments; when nil, the server's default applies.
    ///   - page: 1-based page number; when nil, the server's default applies.
    ///   - limit: maximum number of items to return; when nil, the server's default applies.
    func getPersonDetails(
        personID: Components.Schemas.PersonID,
        sort: Components.Parameters.Sort? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPersonDetailsResponse {
        let response: Operations.getPersonDetails.Output
        do {
            response = try await client.getPersonDetails(query: .init(
                person_id: personID,
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
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
