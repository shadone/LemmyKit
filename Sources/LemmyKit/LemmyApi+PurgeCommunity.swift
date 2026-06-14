//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Purge a community and all of its attached content from the database.
    /// Admin only. This is irreversible.
    func purgeCommunity(
        communityID: Components.Schemas.CommunityID,
        reason: Swift.String? = nil
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.purgeCommunity.Output
        do {
            response = try await client.purgeCommunity(body: .json(.init(
                community_id: communityID,
                reason: reason
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
