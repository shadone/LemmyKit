//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Transfer ownership of a community to another person.
    ///
    /// - Parameters:
    ///   - communityID: the community to transfer.
    ///   - personID: the person who will become the new owner.
    /// - Note: requires authentication as the current community owner or admin.
    func transferCommunity(
        communityID: Components.Schemas.CommunityID,
        personID: Components.Schemas.PersonID
    ) async throws -> Components.Schemas.GetCommunityResponse {
        let response: Operations.transferCommunity.Output
        do {
            response = try await client.transferCommunity(body: .json(.init(
                community_id: communityID,
                person_id: personID
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
