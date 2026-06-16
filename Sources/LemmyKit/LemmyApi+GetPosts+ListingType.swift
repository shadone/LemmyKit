//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get a list of posts of a given `type`.
    ///
    /// - Parameters:
    ///   - showHidden: include posts the user has hidden. When `nil` the
    ///     server's default applies (hidden posts are excluded).
    ///   - showRead: include posts already marked as read. When `nil` the
    ///     account's "show read posts" setting applies.
    ///   - showNSFW: include not-safe-for-work posts. When `nil` the account's
    ///     NSFW setting applies.
    func getPosts(
        type: Components.Schemas.ListingType,
        sort: Components.Schemas.SortType,
        filter: ContentFilter? = nil,
        showHidden: Bool? = nil,
        showRead: Bool? = nil,
        showNSFW: Bool? = nil,
        page: Components.Schemas.PaginationCursor? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetPostsResponse {
        try await getPosts(query: .init(
            type_: type,
            sort: sort,
            limit: limit,
            saved_only: filter?.savedOnly,
            liked_only: filter?.likedOnly,
            disliked_only: filter?.dislikedOnly,
            show_hidden: showHidden,
            show_read: showRead,
            show_nsfw: showNSFW,
            page_cursor: page
        ))
    }
}
