//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Lists communities and returns the version-neutral, cursor-paginated ``Page`` of
    /// ``CommunityView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as
    /// ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``: the v3 client's
    /// `listCommunities` mapped "up" via `neutralCommunityView(fromV3:)`, or the v4 client's
    /// `ListCommunities` mapped near-directly via `neutralCommunityView(fromV4:)`.
    ///
    /// Always lists every community the instance knows of (v3's `.All`/v4's `.all` listing type)
    /// -- there is no per-neutral listing-type parameter here, matching the "must send `.All` or
    /// federated content silently drops" gotcha documented on
    /// ``getCommentsNeutral(postId:sort:pageCursor:)``.
    ///
    /// - Parameters:
    ///   - sort: sort order for the results. **Lossy on v4** -- community listings use a
    ///     materially different sort vocabulary from post listings; see
    ///     `v4CommunitySortType(fromNeutral:)` for the approximation this folds through. v3 reuses
    ///     the same `SortType` as post listings, so its fold is exact
    ///     (`v3SortType(fromNeutral:timeRange:)`, with no time window since community listings
    ///     have no `.top`-style time bucketing).
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page. **v3 has no cursor support for community listings at all** -- v3's
    ///     `listCommunities` only offers classic page/limit pagination, so on a v3 backend this
    ///     parameter is accepted for signature symmetry with v4 but ignored, and the returned
    ///     `Page` always has `nextPage`/`prevPage` both nil (the same shape as
    ///     ``getCommentsNeutral(postId:sort:pageCursor:)``'s v3 path).
    /// - Returns: a `Page` of the neutral `CommunityView`s.
    func listCommunitiesNeutral(
        sort: PostSort,
        pageCursor: Cursor? = nil
    ) async throws -> Page<CommunityView> {
        switch apiVersion {
        case .v3:
            try await listCommunitiesNeutralV3(sort: sort)
        case .v4:
            try await listCommunitiesNeutralV4(sort: sort, pageCursor: pageCursor)
        }
    }
}

private extension LemmyApi {
    /// v3 path: calls the v3 generated client's `listCommunities` operation directly (the same
    /// request-building and response-branching shape as the pre-neutral
    /// ``listCommunities(type:sort:showNSFW:page:limit:)``), then maps the extracted communities
    /// up to the neutral shape. v3's `listCommunities` carries no cursor of any kind, so this
    /// always comes back as a single, complete `Page` (`nextPage`/`prevPage` both nil).
    func listCommunitiesNeutralV3(sort: PostSort) async throws -> Page<CommunityView> {
        let response: Operations.listCommunities.Output
        do {
            response = try await client.listCommunities(query: .init(
                type_: .All,
                sort: v3SortType(fromNeutral: sort, timeRange: nil)
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPage(fromV3: json.communities, nextPage: nil) {
                    neutralCommunityView(fromV3: $0)
                }
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

    /// v4 path: calls the v4 generated client's `ListCommunities` operation, then maps the
    /// extracted v4 items near-directly to the neutral shape. Like `getPostsNeutral`'s v4 path,
    /// v4's `ListCommunities` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func listCommunitiesNeutralV4(sort: PostSort, pageCursor: Cursor?) async throws -> Page<CommunityView> {
        let response: LemmyKitV4Generated.Operations.ListCommunities.Output
        do {
            response = try await v4Client.ListCommunities(query: .init(
                page_cursor: pageCursor?.rawValue,
                sort: v4CommunitySortType(fromNeutral: sort),
                type_: .all
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPage(fromV4: json) { neutralCommunityView(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
