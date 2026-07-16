//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Subscribes to or unsubscribes from a community and returns the version-neutral
    /// ``CommunityView`` reflecting the new follow state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)``/``votePostNeutral(id:direction:)``
    /// shape: both the v3 and v4 clients' `FollowCommunity` operations take the same
    /// `community_id`/`follow` request shape, but v3 narrows `community_id` down to its
    /// `Int32`-backed `CommunityID` (see ``v3CommunityID(_:)``) while v4 takes the neutral
    /// `Int64` id directly. Both extract the returned `community_view` and map it via
    /// `neutralCommunityView(fromV3:)`/`neutralCommunityView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the community to follow or unfollow.
    ///   - follow: true to subscribe, false to unsubscribe.
    /// - Returns: the neutral `CommunityView` reflecting the new follow state.
    /// - Note: requires authentication.
    func followCommunityNeutral(id: Int64, follow: Bool) async throws -> CommunityView {
        switch apiVersion {
        case .v3:
            try await followCommunityNeutralV3(id: id, follow: follow)
        case .v4:
            try await followCommunityNeutralV4(id: id, follow: follow)
        case .piefed:
            try await followCommunityNeutralPiefed(id: id, follow: follow)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``followCommunity(communityID:follow:)``, then maps the extracted v3 `community_view` up
    /// to the neutral shape.
    func followCommunityNeutralV3(id: Int64, follow: Bool) async throws -> CommunityView {
        let communityID = try v3CommunityID(id)

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
                return neutralCommunityView(fromV3: json.community_view)
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

    /// v4 path: calls the v4 generated client's `FollowCommunity` operation, then maps the
    /// extracted v4 `community_view` near-directly to the neutral shape. v4's `FollowCommunity`
    /// only documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases
    /// like v3), so anything else falls through to `.undocumented`.
    func followCommunityNeutralV4(id: Int64, follow: Bool) async throws -> CommunityView {
        let response: LemmyKitV4Generated.Operations.FollowCommunity.Output
        do {
            response = try await v4Client.FollowCommunity(body: .json(.init(
                follow: follow,
                community_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralCommunityView(fromV4: json.community_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.followCommunity(communityId:follow:)` -- PieFed's
    /// membership follow/unfollow (not its separate `PUT /community/subscribe` activity-alert
    /// toggle, which has no Lemmy equivalent and isn't exposed via the neutral facade) -- then
    /// maps the extracted `community_view` up to the neutral shape via
    /// `neutralCommunityView(fromPiefed:)`.
    func followCommunityNeutralPiefed(id: Int64, follow: Bool) async throws -> CommunityView {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "followCommunity") }
        let response = try await piefedClient.followCommunity(communityId: id, follow: follow)
        return neutralCommunityView(fromPiefed: response.community_view)
    }
}
