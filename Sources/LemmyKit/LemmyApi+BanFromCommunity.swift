//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Ban (or unban) the person `personID` from the community `communityID`
    /// as a moderator or admin.
    ///
    /// - Parameters:
    ///   - removeData: when banning, also remove the person's existing posts
    ///     and comments in the community.
    ///   - reason: optional reason recorded in the mod log.
    ///   - expires: optional unix timestamp (seconds) at which the ban lifts;
    ///     `nil` is a permanent ban.
    func banFromCommunity(
        communityID: Components.Schemas.CommunityID,
        personID: Components.Schemas.PersonID,
        ban: Bool,
        removeData: Bool? = nil,
        reason: String? = nil,
        expires: Int64? = nil
    ) async throws -> Components.Schemas.BanFromCommunityResponse {
        let response: Operations.banUserFromCommunity.Output
        do {
            response = try await client.banUserFromCommunity(body: .json(.init(
                community_id: communityID,
                person_id: personID,
                ban: ban,
                remove_data: removeData,
                reason: reason,
                expires: expires
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
