//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Remove or restore a community (moderator action). Pass `removed: true` to
    /// remove, or `false` to restore, optionally with a `reason`.
    func removeCommunity(
        communityID: Components.Schemas.CommunityID,
        removed: Bool,
        reason: String? = nil
    ) async throws -> Components.Schemas.CommunityResponse {
        let response: Operations.removeCommunity.Output
        do {
            response = try await client.removeCommunity(body: .json(.init(
                community_id: communityID,
                removed: removed,
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
