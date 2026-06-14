//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Search Lemmy for `query`.
    ///
    /// Search does not require authentication, but when a credential is set the
    /// results reflect the account's subscribed/saved/vote state.
    ///
    /// - Parameters:
    ///   - query: the search term. Must be non-empty.
    ///   - type: which kind of result to return (All/Posts/Comments/Communities/Users/Url).
    ///   - sort: result ordering.
    ///   - listingType: scope of the search (All/Local/Subscribed/ModeratorView).
    ///   - community: restrict the search to a single community, by id or name.
    ///   - creatorID: restrict the search to a single author.
    ///   - postTitleOnly: when searching posts, match only the title and ignore
    ///     the body. When `nil` the server's default applies.
    ///   - page: 1-based page number.
    ///   - limit: number of results per page.
    func search(
        query: String,
        type: Components.Schemas.SearchType? = nil,
        sort: Components.Schemas.SortType? = nil,
        listingType: Components.Schemas.ListingType? = nil,
        community: CommunityFilter? = nil,
        creatorID: Components.Schemas.PersonID? = nil,
        postTitleOnly: Bool? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.SearchResponse {
        let response: Operations.search.Output
        do {
            response = try await client.search(query: .init(
                q: query,
                community_id: community?.id,
                community_name: community?.name,
                creator_id: creatorID,
                type_: type,
                sort: sort,
                listing_type: listingType,
                page: page,
                limit: limit,
                post_title_only: postTitleOnly
            ))
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
