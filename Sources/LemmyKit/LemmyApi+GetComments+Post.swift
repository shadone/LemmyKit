//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments for a given post.
    ///
    /// - Parameters:
    ///   - postID: the post whose comments to fetch.
    ///   - sort: comment ordering; when nil, the server's default applies.
    ///   - maxDepth: how deep to traverse the comment tree; when nil, the server's default applies.
    ///   - filter: restrict to the viewer's saved or voted comments; nil for no restriction.
    func getComments(
        postID: Components.Schemas.PostID,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil,
        filter: ContentFilter? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        // A post-scoped fetch must not be narrowed by listing type: with no
        // type the server falls back to its default (`Local` on most
        // instances), which drops comments on remote/federated communities
        // even when a post id is given — so a federated post reports its
        // real `comment_count` but the comment list comes back empty.
        // lemmy-ui and Jerboa hardcode `All` on the post page for this reason.
        try await getComments(query: .init(
            type_: .All,
            sort: sort,
            max_depth: maxDepth,
            post_id: postID,
            saved_only: filter?.savedOnly,
            liked_only: filter?.likedOnly,
            disliked_only: filter?.dislikedOnly
        ))
    }
}
