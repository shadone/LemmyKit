//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Ban the person `personID` from the community `communityID` as a
    /// moderator or admin.
    ///
    /// - Parameters:
    ///   - removeData: also remove the person's existing posts and comments in
    ///     the community.
    ///   - reason: optional reason recorded in the mod log.
    ///   - expires: when the ban should lift. Pass `nil` for a permanent ban.
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

    /// Lift an existing community ban on `personID` as a moderator or admin.
    ///
    /// - Parameter reason: optional reason recorded in the mod log.
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
