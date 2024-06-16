//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

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
        let response: Operations.getPosts.Output
        do {
            response = try await client.getPosts(.init(query: .init(
                sort: sort,
                page: page,
                limit: limit,
                community_id: community?.id,
                community_name: community?.name,
                saved_only: filter?.contains(where: \.isSaved),
                liked_only: filter?.contains(where: \.isLiked),
                disliked_only: filter?.contains(where: \.isDisliked)
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// Get a list of posts from a given `community`.
    func getPosts(
        community: CommunityFilter? = nil,
        sort: Components.Schemas.SortType,
        filter: Set<Filter>? = nil,
        page: Components.Schemas.PaginationCursor? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPostsResponse {
        let response: Operations.getPosts.Output
        do {
            response = try await client.getPosts(.init(query: .init(
                sort: sort,
                limit: limit,
                community_id: community?.id,
                community_name: community?.name,
                saved_only: filter?.contains(where: \.isSaved),
                liked_only: filter?.contains(where: \.isLiked),
                disliked_only: filter?.contains(where: \.isDisliked),
                page_cursor: page
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
