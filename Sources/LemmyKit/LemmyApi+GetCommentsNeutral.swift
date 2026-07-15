//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a post's comments and returns the version-neutral, cursor-paginated ``Page`` of
    /// ``CommentView``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``:
    /// the v3 client's `getComments` mapped "up" via `neutralCommentView(fromV3:)`, or the v4
    /// client's `GetComments` mapped near-directly via `neutralCommentView(fromV4:)`.
    ///
    /// Like ``getComments(postID:sort:maxDepth:filter:)``, this always sends v3's listing `type_`
    /// as `.All` (and, symmetrically, v4's `type_` as `.all`): with no listing type the server
    /// falls back to its default (`Local` on most instances), which drops comments on remote/
    /// federated communities even when a post id is given.
    ///
    /// - Parameters:
    ///   - postId: the post whose comments to fetch.
    ///   - sort: the sort order to apply to the returned comments.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page. **v3 has no cursor support for comment listings at all** -- v3's
    ///     `GetCommentsResponse` returns every comment on the post in one response, so on a
    ///     v3-backed instance this parameter is accepted for signature symmetry with v4 but
    ///     ignored, and the returned `Page` always has `nextPage`/`prevPage` both nil.
    /// - Returns: a `Page` of the neutral `CommentView`s for the given post.
    func getCommentsNeutral(
        postId: Int64,
        sort: CommentSort,
        pageCursor: Cursor? = nil
    ) async throws -> Page<CommentView> {
        switch apiVersion {
        case .v3:
            try await getCommentsNeutralV3(postId: postId, sort: sort)
        case .v4:
            try await getCommentsNeutralV4(postId: postId, sort: sort, pageCursor: pageCursor)
        case .piefed:
            try await getCommentsNeutralPiefed(postId: postId, sort: sort, pageCursor: pageCursor)
        }
    }

    /// Fetches a comment SUBTREE -- a parent comment and its descendants -- and returns the
    /// version-neutral, cursor-paginated ``Page`` of ``CommentView``. This is the "load more
    /// replies" fetch: it mirrors ``getCommentsNeutral(postId:sort:pageCursor:)`` but scopes by
    /// parent comment id instead of post id.
    ///
    /// Like the post-scoped fetch it sends v3's listing `type_` as `.All` (v4's as `.all`) so
    /// replies on remote/federated communities are not dropped, and sends **no `max_depth`** -- the
    /// server's page `limit` is the only bound. Any frontier the page cut off re-surfaces as a
    /// fresh "load more" placeholder downstream (driven by each comment's `childCount`).
    ///
    /// - Parameters:
    ///   - parentId: the parent comment whose descendant subtree to fetch.
    ///   - sort: the sort order to apply.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`; nil fetches the first page.
    ///     **v3 has no comment cursor** -- on a v3-backed instance it is ignored and the returned
    ///     `Page` always has `nextPage`/`prevPage` nil (the whole subtree comes in one response).
    /// - Returns: a `Page` of neutral `CommentView`s in the subtree (may include the parent itself).
    func getCommentsNeutral(
        parentId: Int64,
        sort: CommentSort,
        pageCursor: Cursor? = nil
    ) async throws -> Page<CommentView> {
        switch apiVersion {
        case .v3:
            try await getCommentsNeutralV3(parentId: parentId, sort: sort)
        case .v4:
            try await getCommentsNeutralV4(parentId: parentId, sort: sort, pageCursor: pageCursor)
        case .piefed:
            try await getCommentsNeutralPiefed(parentId: parentId, sort: sort, pageCursor: pageCursor)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the shared `getComments(query:)` transport/decoding helper (the same one
    /// ``getComments(postID:sort:maxDepth:filter:)`` forwards to), then maps the extracted v3
    /// comments up to the neutral shape. v3's `GetCommentsResponse` carries no cursor of any
    /// kind -- it returns the whole comment tree for the post in one response -- so this always
    /// comes back as a single, complete `Page` (`nextPage`/`prevPage` both nil).
    func getCommentsNeutralV3(postId: Int64, sort: CommentSort) async throws -> Page<CommentView> {
        let response = try await getComments(query: .init(
            type_: .All,
            sort: v3CommentSortType(fromNeutral: sort),
            community_id: nil,
            post_id: v3PostID(postId)
        ))

        return neutralPage(fromV3: response.comments, nextPage: nil) {
            neutralCommentView(fromV3: $0)
        }
    }

    /// v4 path: calls the v4 generated client's `GetComments` operation, then maps the extracted
    /// v4 items near-directly to the neutral shape. Like `getPostNeutral(id:)`'s v4 path, v4's
    /// `GetComments` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func getCommentsNeutralV4(
        postId: Int64,
        sort: CommentSort,
        pageCursor: Cursor?
    ) async throws -> Page<CommentView> {
        let response: LemmyKitV4Generated.Operations.GetComments.Output
        do {
            response = try await v4Client.GetComments(query: .init(
                post_id: postId,
                page_cursor: pageCursor?.rawValue,
                sort: v4CommentSortType(fromNeutral: sort),
                type_: .all
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPage(fromV4: json) { neutralCommentView(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v3 path for a parent-scoped fetch: reuses the shared `getComments(query:)` transport helper
    /// with `parent_id` set, then maps up to the neutral shape. v3 has no comment cursor, so this
    /// always returns a single, complete `Page` (`nextPage`/`prevPage` nil).
    func getCommentsNeutralV3(parentId: Int64, sort: CommentSort) async throws -> Page<CommentView> {
        let response = try await getComments(query: .init(
            type_: .All,
            sort: v3CommentSortType(fromNeutral: sort),
            parent_id: v3CommentID(parentId)
        ))

        return neutralPage(fromV3: response.comments, nextPage: nil) {
            neutralCommentView(fromV3: $0)
        }
    }

    /// v4 path for a parent-scoped fetch: calls the v4 client's `GetComments` with `parent_id` and
    /// the (optional) cursor, then maps near-directly to the neutral shape.
    func getCommentsNeutralV4(
        parentId: Int64,
        sort: CommentSort,
        pageCursor: Cursor?
    ) async throws -> Page<CommentView> {
        let response: LemmyKitV4Generated.Operations.GetComments.Output
        do {
            response = try await v4Client.GetComments(query: .init(
                parent_id: parentId,
                page_cursor: pageCursor?.rawValue,
                sort: v4CommentSortType(fromNeutral: sort),
                type_: .all
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPage(fromV4: json) { neutralCommentView(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path for the post-scoped fetch: calls `PiefedClient.getComments(postId:sort:page:)`
    /// (`sort` folded via `piefedCommentSort(_:)`) and maps the extracted items up to the neutral
    /// shape. Unlike v3, **PieFed's comment listing DOES page** (confirmed live against
    /// `piefed.social`: `page=N` is honored and `next_page` echoes the following page number), so
    /// `pageCursor` is forwarded and the returned `Page` carries a real `nextPage` when there's
    /// more.
    func getCommentsNeutralPiefed(postId: Int64, sort: CommentSort, pageCursor: Cursor?) async throws -> Page<CommentView> {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getComments") }

        let response = try await piefedClient.getComments(
            postId: postId,
            sort: piefedCommentSort(sort),
            page: pageCursor.flatMap { Int($0.rawValue) }
        )

        return neutralPage(fromPiefed: response.comments, nextPage: response.next_page) {
            neutralCommentView(fromPiefed: $0)
        }
    }

    /// PieFed path for the parent-scoped fetch ("load more replies"): calls
    /// `PiefedClient.getComments(parentId:sort:page:)`, otherwise identical to the post-scoped
    /// path above.
    func getCommentsNeutralPiefed(parentId: Int64, sort: CommentSort, pageCursor: Cursor?) async throws -> Page<CommentView> {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getComments") }

        let response = try await piefedClient.getComments(
            parentId: parentId,
            sort: piefedCommentSort(sort),
            page: pageCursor.flatMap { Int($0.rawValue) }
        )

        return neutralPage(fromPiefed: response.comments, nextPage: response.next_page) {
            neutralCommentView(fromPiefed: $0)
        }
    }
}
