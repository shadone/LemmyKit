//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List registration applications.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread (pending) applications; optional, when nil the server's default applies.
    ///   - page: 1-based page number; optional, when nil the server's default applies.
    ///   - limit: maximum number of results to return; optional, when nil the server's default applies.
    /// - Note: admin only.
    func listRegistrationApplications(
        unreadOnly: Components.Parameters.UnreadOnly? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.ListRegistrationApplicationsResponse {
        let response: Operations.listRegistrationApplications.Output
        do {
            response = try await client.listRegistrationApplications(query: .init(
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
