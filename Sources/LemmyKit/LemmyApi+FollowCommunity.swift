//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Subscribe to or unsubscribe from a community.
    ///
    /// - Parameters:
    ///   - communityID: the community to follow or unfollow.
    ///   - follow: true to subscribe, false to unsubscribe.
    /// - Note: requires authentication.
    func followCommunity(
        communityID: Components.Schemas.CommunityID,
        follow: Bool
    ) async throws -> Components.Schemas.CommunityResponse {
        let response: Operations.followCommunity.Output
        do {
            response = try await client.followCommunity(body: .json(.init(
                community_id: communityID,
                follow: follow
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
