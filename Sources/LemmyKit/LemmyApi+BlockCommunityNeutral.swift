//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Blocks or unblocks the community `id` for the signed-in account and returns the
    /// version-neutral ``CommunityView`` for the (un)blocked community.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's
    /// `blockCommunity` mapped "up" via `neutralCommunityView(fromV3:)`, or the v4 client's
    /// `BlockCommunity` mapped near-directly via `neutralCommunityView(fromV4:)`. Both response
    /// bodies also carry a `blocked` flag confirming the request took effect, but since it always
    /// mirrors the `block` argument on success, this method doesn't surface it separately --
    /// only the resulting `CommunityView` is returned.
    ///
    /// - Parameters:
    ///   - id: the community to block or unblock.
    ///   - block: true to block, false to unblock.
    /// - Returns: the neutral `CommunityView` for the (un)blocked community.
    /// - Note: requires authentication.
    func blockCommunityNeutral(id: Int64, block: Bool) async throws -> CommunityView {
        switch apiVersion {
        case .v3:
            try await blockCommunityNeutralV3(id: id, block: block)
        case .v4:
            try await blockCommunityNeutralV4(id: id, block: block)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "blockCommunity")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``blockCommunity(communityID:block:)``, then maps the extracted v3 `community_view` up to
    /// the neutral shape.
    func blockCommunityNeutralV3(id: Int64, block: Bool) async throws -> CommunityView {
        let communityID = try v3CommunityID(id)

        let response: Operations.blockCommunity.Output
        do {
            response = try await client.blockCommunity(body: .json(.init(
                community_id: communityID,
                block: block
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

    /// v4 path: calls the v4 generated client's `BlockCommunity` operation, then maps the
    /// extracted v4 `community_view` near-directly to the neutral shape. Unlike v3's
    /// `BlockCommunityResponse`, v4's `BlockCommunity` returns a bare `CommunityResponse`
    /// (`{ discussion_languages, community_view }`, no top-level `blocked` flag) -- not needed
    /// here regardless, since this method only returns the `CommunityView`. v4's
    /// `BlockCommunity` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func blockCommunityNeutralV4(id: Int64, block: Bool) async throws -> CommunityView {
        let response: LemmyKitV4Generated.Operations.BlockCommunity.Output
        do {
            response = try await v4Client.BlockCommunity(body: .json(.init(
                block: block,
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
}
