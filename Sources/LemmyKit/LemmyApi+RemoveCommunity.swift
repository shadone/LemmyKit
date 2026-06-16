//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Remove or restore a community as a moderator action.
    ///
    /// - Parameters:
    ///   - communityID: the community to remove or restore.
    ///   - removed: true to remove, false to restore a previously removed community.
    ///   - reason: optional reason recorded in the mod log.
    /// - Note: requires moderator or admin.
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
