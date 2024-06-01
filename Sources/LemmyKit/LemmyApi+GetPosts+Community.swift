//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import Combine

public extension LemmyApi {
    /// Get a list of posts from a given `community`.
    @available(*, deprecated)
    func getPosts(
        community: CommunityFilter? = nil,
        sort: Components.Schemas.SortType,
        filter: Set<Filter>? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPostsResponse {
        let response = try await client.getPosts(.init(query: .init(
            sort: sort,
            page: page,
            limit: limit,
            community_id: community?.id,
            community_name: community?.name,
            saved_only: filter?.contains(where: \.isSaved),
            liked_only: filter?.contains(where: \.isLiked),
            disliked_only: filter?.contains(where: \.isDisliked)
        )))
        return try response.ok.body.json
    }

    @available(*, deprecated)
    func getPosts(
        community: CommunityFilter? = nil,
        sort: Components.Schemas.SortType,
        filter: Set<Filter>? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) -> AnyPublisher<Components.Schemas.GetPostsResponse, LemmyApiError> {
        Future {
            try await self.getPosts(
                community: community,
                sort: sort,
                filter: filter,
                page: page,
                limit: limit
            )
        }.eraseToAnyPublisher()
    }

    /// Get a list of posts from a given `community`.
    func getPosts(
        community: CommunityFilter? = nil,
        sort: Components.Schemas.SortType,
        filter: Set<Filter>? = nil,
        page: Components.Schemas.PaginationCursor? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPostsResponse {
        let response = try await client.getPosts(.init(query: .init(
            sort: sort,
            limit: limit,
            community_id: community?.id,
            community_name: community?.name,
            saved_only: filter?.contains(where: \.isSaved),
            liked_only: filter?.contains(where: \.isLiked),
            disliked_only: filter?.contains(where: \.isDisliked),
            page_cursor: page
        )))
        return try response.ok.body.json
    }
}
