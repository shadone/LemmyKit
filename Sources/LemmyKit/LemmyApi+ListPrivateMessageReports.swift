//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List private message reports visible to the logged-in admin.
    ///
    /// - Parameters:
    ///   - unresolvedOnly: when true, return only reports that have not yet been resolved.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of reports to return.
    /// - Note: requires authentication.
    func listPrivateMessageReports(
        unresolvedOnly: Components.Parameters.UnresolvedOnly? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.ListPrivateMessageReportsResponse {
        let response: Operations.listPrivateMessageReports.Output
        do {
            response = try await client.listPrivateMessageReports(query: .init(
                unresolved_only: unresolvedOnly,
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
