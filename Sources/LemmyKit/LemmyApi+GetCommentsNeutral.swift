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
    /// ``ApiVersion``), following the same shape as ``getPostsNeutral(listingType:sort:communityId:timeRange:pageCursor:)``:
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
}
