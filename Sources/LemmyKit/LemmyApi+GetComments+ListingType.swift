//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments for a given listing `type`.
    func getComments(
        type: Components.Schemas.ListingType,
        sort: Components.Schemas.CommentSortType? = nil,
        filter: ContentFilter? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        try await getComments(query: .init(
            type_: type,
            sort: sort,
            page: page,
            limit: limit,
            saved_only: filter?.savedOnly,
            liked_only: filter?.likedOnly,
            disliked_only: filter?.dislikedOnly
        ))
    }
}
