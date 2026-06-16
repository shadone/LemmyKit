//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments in a given `community`.
    func getComments(
        community: CommunityFilter,
        sort: Components.Schemas.CommentSortType? = nil,
        filter: Set<Filter>? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        try await getComments(query: .init(
            sort: sort,
            page: page,
            limit: limit,
            community_id: community.id,
            community_name: community.name,
            saved_only: filter?.contains(where: \.isSaved),
            liked_only: filter?.contains(where: \.isLiked),
            disliked_only: filter?.contains(where: \.isDisliked)
        ))
    }
}
