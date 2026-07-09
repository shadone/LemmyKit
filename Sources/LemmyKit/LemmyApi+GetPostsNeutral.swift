//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a page of posts and returns the version-neutral, cursor-paginated ``Page`` of
    /// ``PostView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as ``getPostNeutral(id:)``: the v3 client's
    /// `getPosts` mapped "up" via `neutralPostView(fromV3:)`, or the v4 client's `GetPosts` mapped
    /// near-directly via `neutralPostView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - listingType: the listing scope (e.g. local, subscribed, all).
    ///   - sort: the sort order to apply to the returned posts.
    ///   - communityId: restrict results to this community; nil for no community restriction.
    ///   - timeRange: the top-N time window to pair with `sort == .top`; ignored for every other
    ///     sort. On a v3 backend this folds to the nearest of v3's fixed time buckets (see
    ///     `v3SortType(fromNeutral:timeRange:)`); on v4 it is sent as-is via `time_range_seconds`.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page.
    /// - Returns: a `Page` of the neutral `PostView`s matching the given scope and sort.
    func getPostsNeutral(
        listingType: Lemmy.ListingType,
        sort: PostSort,
        communityId: Int64? = nil,
        timeRange: TimeRange? = nil,
        pageCursor: Cursor? = nil
    ) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            try await getPostsNeutralV3(
                listingType: listingType,
                sort: sort,
                communityId: communityId,
                timeRange: timeRange,
                pageCursor: pageCursor
            )
        case .v4:
            try await getPostsNeutralV4(
                listingType: listingType,
                sort: sort,
                communityId: communityId,
                timeRange: timeRange,
                pageCursor: pageCursor
            )
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the shared `getPosts(query:)` transport/decoding helper (the same one the
    /// scope-pure `getPosts(type:...)`/`getPosts(community:...)` overloads forward to), then maps
    /// the extracted v3 posts up to the neutral shape. v3's `GetPostsResponse` carries only a
    /// forward `next_page` cursor -- no previous-page cursor -- so the returned `Page`'s
    /// `prevPage` is always nil (see `neutralPage(fromV3:nextPage:mapItem:)`).
    func getPostsNeutralV3(
        listingType: Lemmy.ListingType,
        sort: PostSort,
        communityId: Int64?,
        timeRange: TimeRange?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        let response = try await getPosts(query: .init(
            type_: listingType,
            sort: v3SortType(fromNeutral: sort, timeRange: timeRange),
            community_id: communityId.map(Components.Schemas.CommunityID.init),
            page_cursor: pageCursor?.rawValue
        ))

        return neutralPage(fromV3: response.posts, nextPage: response.next_page) {
            neutralPostView(fromV3: $0)
        }
    }

    /// v4 path: calls the v4 generated client's `GetPosts` operation, then maps the extracted v4
    /// items near-directly to the neutral shape. Like `getPostNeutral(id:)`'s v4 path, v4's
    /// `GetPosts` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func getPostsNeutralV4(
        listingType: Lemmy.ListingType,
        sort: PostSort,
        communityId: Int64?,
        timeRange: TimeRange?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.GetPosts.Output
        do {
            response = try await v4Client.GetPosts(query: .init(
                page_cursor: pageCursor?.rawValue,
                community_id: communityId,
                time_range_seconds: timeRange?.seconds,
                sort: v4PostSortType(fromNeutral: sort),
                type_: v4ListingType(fromNeutral: listingType)
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPage(fromV4: json) { neutralPostView(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
