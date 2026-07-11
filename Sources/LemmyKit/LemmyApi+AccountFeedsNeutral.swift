//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a page of the viewer's saved posts and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PostView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as
    /// ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``: the v3 client's
    /// `getPosts` (with `saved_only` set) mapped "up" via `neutralPostView(fromV3:)`, or the v4
    /// client's `ListPersonSaved` mapped via `expectedPostView(fromV4Combined:)`.
    ///
    /// v4's `ListPersonSaved` serves a combined post/comment feed; this method requests
    /// `type_: .posts` to restrict the server-side result to posts only, so the comment branch
    /// should never appear (see `expectedPostView(fromV4Combined:)`'s doc for the defensive throw
    /// if it somehow does). v3 has no listing-type concept beyond `saved_only`, so
    /// ``Lemmy/ListingType/All`` is sent explicitly -- the same gotcha `getCommentsNeutral`
    /// documents: omitting a listing type defaults the server to `Local` and silently drops
    /// federated content, and saved posts frequently live on remote instances.
    ///
    /// - Parameters:
    ///   - sort: the sort order to apply to the saved feed. On v3 this is forwarded to `getPosts`
    ///     (the same fold ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``
    ///     uses). **v4's `ListPersonSaved` has no sort parameter**, so on a v4 backend this is a
    ///     documented no-op and the server's default saved-feed order is returned. nil defers to
    ///     each backend's default.
    ///   - timeRange: the top-N time window to pair with `sort == .top`; ignored for every other
    ///     sort, and ignored entirely on v4 (which has no saved-feed sort at all, see `sort`).
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil
    ///     fetches the first page. `prevPage` is always nil on a v3 backend (no reverse-paging
    ///     cursor, see `Page`'s doc).
    /// - Returns: a `Page` of the neutral `PostView`s the viewer has saved.
    func getSavedPostsNeutral(
        sort: PostSort? = nil,
        timeRange: TimeRange? = nil,
        pageCursor: Cursor? = nil
    ) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            try await getSavedPostsNeutralV3(sort: sort, timeRange: timeRange, pageCursor: pageCursor)
        case .v4:
            try await getSavedPostsNeutralV4(pageCursor: pageCursor)
        }
    }

    /// Fetches a page of posts the viewer has marked as read and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PostView``.
    ///
    /// v4 serves this natively via `ListPersonRead`. **v3 has no equivalent**: `getPosts`'s
    /// `show_read` flag only *includes* already-read posts alongside unread ones in the general
    /// listing -- unlike `saved_only`/`liked_only`, it does not isolate read posts on their own.
    /// Rather than mislabel a mixed read+unread listing as "read posts", the v3 path always
    /// returns an empty page without making a network call.
    ///
    /// - Parameter pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil
    ///   fetches the first page. Ignored on a v3 backend, which always returns a single empty
    ///   page (see above).
    /// - Returns: a `Page` of the neutral `PostView`s the viewer has read; always empty on a v3
    ///   backend.
    func getReadPostsNeutral(pageCursor: Cursor? = nil) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            Page(items: [], nextPage: nil, prevPage: nil)
        case .v4:
            try await getReadPostsNeutralV4(pageCursor: pageCursor)
        }
    }

    /// Fetches a page of posts the viewer has hidden and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PostView``.
    ///
    /// v4 serves this natively via `ListPersonHidden`. **v3 has no equivalent**: `getPosts`'s
    /// `show_hidden` flag only *includes* hidden posts alongside non-hidden ones -- like
    /// `show_read`, it isn't a hidden-only filter. The v3 path always returns an empty page
    /// without making a network call, for the same reason ``getReadPostsNeutral(pageCursor:)``
    /// does.
    ///
    /// - Parameter pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil
    ///   fetches the first page. Ignored on a v3 backend, which always returns a single empty
    ///   page (see above).
    /// - Returns: a `Page` of the neutral `PostView`s the viewer has hidden; always empty on a v3
    ///   backend.
    func getHiddenPostsNeutral(pageCursor: Cursor? = nil) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            Page(items: [], nextPage: nil, prevPage: nil)
        case .v4:
            try await getHiddenPostsNeutralV4(pageCursor: pageCursor)
        }
    }

    /// Fetches a page of posts the viewer has upvoted and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PostView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with: the v3
    /// client's `getPosts` (with `liked_only` set) mapped "up" via `neutralPostView(fromV3:)`, or
    /// the v4 client's `ListPersonLiked` mapped via `expectedPostView(fromV4Combined:)`.
    ///
    /// v4's `ListPersonLiked` also serves disliked content, so `like_type: .liked_only` is sent
    /// explicitly to pin the direction; like `getSavedPostsNeutral(sort:timeRange:pageCursor:)`, it additionally
    /// serves a combined post/comment feed, so `type_: .posts` restricts the server-side result
    /// to posts only. v3 sends ``Lemmy/ListingType/All`` explicitly, for the same federated-content
    /// reason ``getSavedPostsNeutral(sort:timeRange:pageCursor:)`` documents.
    ///
    /// - Parameter pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil
    ///   fetches the first page. `prevPage` is always nil on a v3 backend (no reverse-paging
    ///   cursor, see `Page`'s doc).
    /// - Returns: a `Page` of the neutral `PostView`s the viewer has upvoted.
    func getLikedPostsNeutral(pageCursor: Cursor? = nil) async throws -> Page<PostView> {
        switch apiVersion {
        case .v3:
            try await getLikedPostsNeutralV3(pageCursor: pageCursor)
        case .v4:
            try await getLikedPostsNeutralV4(pageCursor: pageCursor)
        }
    }
}

/// A v4 combined post/comment feed item decoded without a post branch, despite the request having
/// been scoped to `type_: .posts` (`ListPersonSaved`/`ListPersonLiked`) -- not expected in
/// practice, see `expectedPostView(fromV4Combined:)`.
private enum AccountFeedsNeutralError: Error, Equatable {
    case missingPostBranch
}

/// Extracts the post branch from a v4 combined post/comment view requested with `type_: .posts`
/// (see `getSavedPostsNeutralV4(pageCursor:)`/`getLikedPostsNeutralV4(pageCursor:)`), so the
/// comment branch should never be present.
///
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``AccountFeedsNeutralError/missingPostBranch``
///   if the post branch isn't present -- a server ignoring the `type_` filter shouldn't silently
///   drop or mis-map content as a post.
private func expectedPostView(
    fromV4Combined combined: LemmyKitV4Generated.Components.Schemas.PostCommentCombinedView
) throws -> PostView {
    guard let post = combined.value1 else {
        throw LemmyApiError.unknown(AccountFeedsNeutralError.missingPostBranch)
    }
    return neutralPostView(fromV4: post.value2)
}

private extension LemmyApi {
    /// v3 path: reuses the shared `getPosts(query:)` transport/decoding helper with `saved_only`
    /// set, then maps the extracted v3 posts up to the neutral shape. `type_: .All` avoids the
    /// server silently narrowing to `Local` -- see
    /// ``LemmyApi/getSavedPostsNeutral(sort:timeRange:pageCursor:)``'s doc. `sort` is folded to
    /// v3's fused `SortType` via the shared `v3SortType(fromNeutral:timeRange:)`; nil sends no
    /// sort (server default).
    func getSavedPostsNeutralV3(
        sort: PostSort?,
        timeRange: TimeRange?,
        pageCursor: Cursor?
    ) async throws -> Page<PostView> {
        let response = try await getPosts(query: .init(
            type_: .All,
            sort: sort.map { v3SortType(fromNeutral: $0, timeRange: timeRange) },
            saved_only: true,
            page_cursor: pageCursor?.rawValue
        ))

        return neutralPage(fromV3: response.posts, nextPage: response.next_page) {
            neutralPostView(fromV3: $0)
        }
    }

    /// v4 path: calls `ListPersonSaved` with `type_: .posts` (server-side post-only filter over
    /// v4's combined post/comment feed), then maps each extracted item to the neutral shape via
    /// `expectedPostView(fromV4Combined:)`. Like `getPostsNeutral`'s v4 path, `ListPersonSaved`
    /// only documents the `ok` response, so anything else falls through to `.undocumented`.
    ///
    /// `ListPersonSaved` has no `sort` query parameter, so ``LemmyApi/getSavedPostsNeutral(sort:timeRange:pageCursor:)``'s
    /// `sort`/`timeRange` cannot be honored here -- the server's default saved-feed order is
    /// returned unchanged.
    func getSavedPostsNeutralV4(pageCursor: Cursor?) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.ListPersonSaved.Output
        do {
            response = try await v4Client.ListPersonSaved(query: .init(
                page_cursor: pageCursor?.rawValue,
                type_: .posts
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return try neutralPage(fromV4: json) { try expectedPostView(fromV4Combined: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 path for ``LemmyApi/getReadPostsNeutral(pageCursor:)`` -- `ListPersonRead` returns a
    /// plain `PagedResponse_PostView_` (no combined view, unlike saved/liked), so each item maps
    /// directly via `neutralPostView(fromV4:)`.
    func getReadPostsNeutralV4(pageCursor: Cursor?) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.ListPersonRead.Output
        do {
            response = try await v4Client.ListPersonRead(query: .init(page_cursor: pageCursor?.rawValue))
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

    /// v4 path for ``LemmyApi/getHiddenPostsNeutral(pageCursor:)`` -- `ListPersonHidden` returns
    /// a plain `PagedResponse_PostView_`, the same shape `ListPersonRead` does.
    func getHiddenPostsNeutralV4(pageCursor: Cursor?) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.ListPersonHidden.Output
        do {
            response = try await v4Client.ListPersonHidden(query: .init(page_cursor: pageCursor?.rawValue))
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

    /// v3 path: `liked_only` set, `type_: .All` for the same federated-content reason
    /// ``getSavedPostsNeutralV3(pageCursor:)`` documents.
    func getLikedPostsNeutralV3(pageCursor: Cursor?) async throws -> Page<PostView> {
        let response = try await getPosts(query: .init(
            type_: .All,
            liked_only: true,
            page_cursor: pageCursor?.rawValue
        ))

        return neutralPage(fromV3: response.posts, nextPage: response.next_page) {
            neutralPostView(fromV3: $0)
        }
    }

    /// v4 path: `ListPersonLiked` with `like_type: .liked_only` (the endpoint also serves
    /// disliked content) and `type_: .posts` (server-side post-only filter, same as
    /// `getSavedPostsNeutralV4(pageCursor:)`), then maps via `expectedPostView(fromV4Combined:)`.
    func getLikedPostsNeutralV4(pageCursor: Cursor?) async throws -> Page<PostView> {
        let response: LemmyKitV4Generated.Operations.ListPersonLiked.Output
        do {
            response = try await v4Client.ListPersonLiked(query: .init(
                page_cursor: pageCursor?.rawValue,
                like_type: .liked_only,
                type_: .posts
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return try neutralPage(fromV4: json) { try expectedPostView(fromV4Combined: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
