//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get a list of posts from a given `community`.
    ///
    /// - Parameters:
    ///   - showHidden: include posts the user has hidden. When `nil` the
    ///     server's default applies (hidden posts are excluded).
    ///   - showRead: include posts already marked as read. When `nil` the
    ///     account's "show read posts" setting applies.
    ///   - showNSFW: include not-safe-for-work posts. When `nil` the account's
    ///     NSFW setting applies.
    func getPosts(
        community: CommunityFilter? = nil,
        sort: Components.Schemas.SortType,
        filter: Set<Filter>? = nil,
        showHidden: Bool? = nil,
        showRead: Bool? = nil,
        showNSFW: Bool? = nil,
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
                show_hidden: showHidden,
                show_read: showRead,
                show_nsfw: showNSFW,
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
