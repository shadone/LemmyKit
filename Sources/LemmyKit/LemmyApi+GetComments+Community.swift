//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments in a given `community`.
    ///
    /// - Parameters:
    ///   - community: the community to fetch comments from, by id or name.
    ///   - sort: comment ordering; when nil, the server's default applies.
    ///   - filter: restrict to the viewer's saved or voted comments; nil for no restriction.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of comments to return.
    func getComments(
        community: CommunityFilter,
        sort: Components.Schemas.CommentSortType? = nil,
        filter: ContentFilter? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        try await getComments(query: .init(
            sort: sort,
            page: page,
            limit: limit,
            community_id: community.id,
            community_name: community.name,
            saved_only: filter?.savedOnly,
            liked_only: filter?.likedOnly,
            disliked_only: filter?.dislikedOnly
        ))
    }
}
