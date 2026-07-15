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
    ///   - showNsfw: true to include NSFW posts even when the account's setting hides them, false
    ///     to force-hide them; nil defers to the account's `show_nsfw` preference. Sent server-side
    ///     on both backends (v3 `getPosts`'s `show_nsfw`, v4 `GetPosts`'s `show_nsfw`).
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page.
    /// - Returns: a `Page` of the neutral `PostView`s matching the given scope and sort.
    func getPostsNeutral(
        listingType: Lemmy.ListingType,
        sort: PostSort,
        communityId: Int64? = nil,
        timeRange: TimeRange? = nil,
        showNsfw: Bool? = nil,
        pageCursor: Cursor? = nil
    ) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            try await getPostsNeutralV3(
                listingType: listingType,
                sort: sort,
                communityId: communityId,
                timeRange: timeRange,
                showNsfw: showNsfw,
                pageCursor: pageCursor
            )
        case .v4:
            try await getPostsNeutralV4(
                listingType: listingType,
                sort: sort,
                communityId: communityId,
                timeRange: timeRange,
                showNsfw: showNsfw,
                pageCursor: pageCursor
            )
        case .piefed:
            try await getPostsNeutralPiefed(
                listingType: listingType,
                sort: sort,
                communityId: communityId,
                timeRange: timeRange,
                showNsfw: showNsfw,
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
        showNsfw: Bool?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        let response = try await getPosts(query: .init(
            type_: listingType,
            sort: v3SortType(fromNeutral: sort, timeRange: timeRange),
            community_id: communityId.map(v3CommunityID),
            show_nsfw: showNsfw,
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
        showNsfw: Bool?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.GetPosts.Output
        do {
            response = try await v4Client.GetPosts(query: .init(
                page_cursor: pageCursor?.rawValue,
                show_nsfw: showNsfw,
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

    /// PieFed path: maps the neutral listing type/sort to PieFed's `type_`/`sort` wire strings
    /// (`Lemmy.ListingType`'s `rawValue` passes straight through -- PieFed's `type_` accepts the
    /// same case names as v3's `ListingType`; `piefedSort(_:timeRange:)` folds `sort`/`timeRange`
    /// the same way the v3 path does), then maps the extracted items up to the neutral shape.
    /// PieFed's `page` is a plain 1-based integer (unlike v4's opaque cursor) that PieFed echoes
    /// back as `next_page` -- `pageCursor`'s `rawValue` round-trips through that integer via
    /// `neutralPage(fromPiefed:nextPage:mapItem:)`/`neutralCursor(fromPiefed:)`.
    func getPostsNeutralPiefed(
        listingType: Lemmy.ListingType,
        sort: PostSort,
        communityId: Int64?,
        timeRange: TimeRange?,
        showNsfw: Bool?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getPosts") }

        let response = try await piefedClient.getPosts(
            type_: listingType.rawValue,
            sort: piefedSort(sort, timeRange: timeRange),
            communityId: communityId,
            showNsfw: showNsfw,
            page: pageCursor.flatMap { Int($0.rawValue) }
        )

        return neutralPage(fromPiefed: response.posts, nextPage: response.next_page) {
            neutralPostView(fromPiefed: $0)
        }
    }
}
