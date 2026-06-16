//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch a page of posts matching a given listing `type`.
    ///
    /// - Parameters:
    ///   - type: the listing scope (e.g. local, subscribed, all).
    ///   - sort: the sort order to apply to the returned posts.
    ///   - filter: optional content filter restricting results to saved, liked, or disliked posts; nil returns all posts.
    ///   - showHidden: true to include posts the user has hidden; when nil the server's default applies (hidden posts are excluded).
    ///   - showRead: true to include posts already marked as read; when nil the account's "show read posts" setting applies.
    ///   - showNSFW: true to include not-safe-for-work posts; when nil the account's NSFW setting applies.
    ///   - page: opaque pagination cursor for the next page; nil fetches the first page.
    ///   - limit: maximum number of posts to return; when nil the server's default applies.
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
