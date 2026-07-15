//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a community by its id and returns the version-neutral ``CommunityView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's
    /// `getCommunity` mapped "up" via `neutralCommunityView(fromV3:)`, or the v4 client's
    /// `GetCommunity` mapped near-directly via `neutralCommunityView(fromV4:)`.
    ///
    /// Named `getCommunityNeutral` (rather than `getCommunity`) to avoid clashing with the
    /// existing v3-only ``getCommunity(communityID:)``/``getCommunity(name:)``; a later step
    /// retargets/renames once every caller has moved onto the neutral surface.
    ///
    /// - Parameter id: the community to fetch.
    /// - Returns: the neutral `CommunityView` for the requested community.
    func getCommunityNeutral(id: Int64) async throws -> CommunityView {
        switch apiVersion {
        case .v3:
            try await getCommunityNeutralV3(id: id)
        case .v4:
            try await getCommunityNeutralV4(id: id)
        case .piefed:
            try await getCommunityNeutralPiefed(id: id)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``getCommunity(communityID:)``, then maps the extracted v3 `community_view` up to the
    /// neutral shape.
    func getCommunityNeutralV3(id: Int64) async throws -> CommunityView {
        let communityID = try v3CommunityID(id)

        let response: Operations.getCommunity.Output
        do {
            response = try await client.getCommunity(query: .init(id: communityID, name: nil))
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

    /// v4 path: calls the v4 generated client's `GetCommunity` operation, then maps the
    /// extracted v4 `community_view` near-directly to the neutral shape. v4's `GetCommunity`
    /// only documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases
    /// like v3), so anything else falls through to `.undocumented`.
    func getCommunityNeutralV4(id: Int64) async throws -> CommunityView {
        let response: LemmyKitV4Generated.Operations.GetCommunity.Output
        do {
            response = try await v4Client.GetCommunity(query: .init(name: nil, id: id))
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

    /// PieFed path: calls `PiefedClient.getCommunity(id:)`, then maps the extracted
    /// `community_view` to the neutral shape.
    func getCommunityNeutralPiefed(id: Int64) async throws -> CommunityView {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getCommunity") }
        let response = try await piefedClient.getCommunity(id: id)
        return neutralCommunityView(fromPiefed: response.community_view)
    }
}
