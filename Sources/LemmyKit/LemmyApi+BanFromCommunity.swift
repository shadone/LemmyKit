//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Ban a person from a community as a moderator or admin.
    ///
    /// - Parameters:
    ///   - communityID: the community to ban from.
    ///   - personID: the person to ban.
    ///   - removeData: true to also remove the person's existing posts and comments in the community.
    ///   - reason: optional reason recorded in the mod log.
    ///   - expires: when the ban should lift; nil for a permanent ban.
    /// - Note: requires moderator or admin.
    func banFromCommunity(
        communityID: Components.Schemas.CommunityID,
        personID: Components.Schemas.PersonID,
        removeData: Bool? = nil,
        reason: String? = nil,
        expires: Date? = nil
    ) async throws -> Components.Schemas.BanFromCommunityResponse {
        try await sendBanFromCommunity(.init(
            community_id: communityID,
            person_id: personID,
            ban: true,
            remove_data: removeData,
            reason: reason,
            expires: expires.map { Int64($0.timeIntervalSince1970) }
        ))
    }

    /// Lift an existing community ban on a person as a moderator or admin.
    ///
    /// - Parameters:
    ///   - communityID: the community to lift the ban in.
    ///   - personID: the person to unban.
    ///   - reason: optional reason recorded in the mod log.
    /// - Note: requires moderator or admin.
    func unbanFromCommunity(
        communityID: Components.Schemas.CommunityID,
        personID: Components.Schemas.PersonID,
        reason: String? = nil
    ) async throws -> Components.Schemas.BanFromCommunityResponse {
        try await sendBanFromCommunity(.init(
            community_id: communityID,
            person_id: personID,
            ban: false,
            remove_data: nil,
            reason: reason,
            expires: nil
        ))
    }

    private func sendBanFromCommunity(
        _ body: Components.Schemas.BanFromCommunity
    ) async throws -> Components.Schemas.BanFromCommunityResponse {
        let response: Operations.banUserFromCommunity.Output
        do {
            response = try await client.banUserFromCommunity(body: .json(body))
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
