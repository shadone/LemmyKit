//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Add or remove a moderator on a community. Pass `added: true` to add the
    /// person as a moderator, or `false` to remove them.
    func addModToCommunity(
        communityID: Components.Schemas.CommunityID,
        personID: Components.Schemas.PersonID,
        added: Bool
    ) async throws -> Components.Schemas.AddModToCommunityResponse {
        let response: Operations.addModToCommunity.Output
        do {
            response = try await client.addModToCommunity(body: .json(.init(
                community_id: communityID,
                person_id: personID,
                added: added
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
