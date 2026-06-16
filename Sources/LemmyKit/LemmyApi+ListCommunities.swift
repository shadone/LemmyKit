//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List communities matching the given listing type, with optional sorting and pagination.
    ///
    /// - Parameters:
    ///   - type: the scope of communities to return (e.g. subscribed, local, all).
    ///   - sort: sort order for the results; nil uses the server default.
    ///   - showNSFW: true to include NSFW communities in the results; nil uses the server default.
    ///   - page: 1-based page number; nil returns the first page.
    ///   - limit: maximum number of communities to return; nil uses the server default.
    func listCommunities(
        type: Components.Schemas.ListingType,
        sort: Components.Parameters.Sort? = nil,
        showNSFW: Bool? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.ListCommunitiesResponse {
        let response: Operations.listCommunities.Output
        do {
            response = try await client.listCommunities(query: .init(
                type_: type,
                sort: sort,
                show_nsfw: showNSFW,
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
