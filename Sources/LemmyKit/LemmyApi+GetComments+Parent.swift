//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of replies under a given parent comment.
    func getComments(
        parentID: Components.Schemas.CommentID,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil,
        filter: ContentFilter? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        // As with a post-scoped fetch, a thread must not be narrowed by
        // listing type: with no type the server falls back to its default
        // (`Local` on most instances), which drops replies on
        // remote/federated communities even when a parent id is given.
        try await getComments(query: .init(
            type_: .All,
            sort: sort,
            max_depth: maxDepth,
            parent_id: parentID,
            saved_only: filter?.savedOnly,
            liked_only: filter?.likedOnly,
            disliked_only: filter?.dislikedOnly
        ))
    }
}
