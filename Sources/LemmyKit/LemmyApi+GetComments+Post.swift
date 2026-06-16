//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments for a given post.
    func getComments(
        postID: Components.Schemas.PostID,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil,
        filter: Set<Filter>? = nil
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
            saved_only: filter?.contains(where: \.isSaved),
            liked_only: filter?.contains(where: \.isLiked),
            disliked_only: filter?.contains(where: \.isDisliked)
        ))
    }
}
