//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The version-neutral result of a search: every matched post/comment/community/person, plus a
/// bidirectional cursor for paging through more.
///
/// This is v4-shaped: v4's `SearchResponse` renamed v3's `users` array to `persons` (matching the
/// rest of this package's neutral vocabulary, `PersonView`/`Person`) and added forward/backward
/// pagination cursors, which this type carries as `nextPage`/`prevPage` -- see the V3/V4 mapping
/// functions in `Adapters/SearchResultsV3Mapping.swift`/`SearchResultsV4Mapping.swift` for how
/// each backend's raw response is folded into this shape. v3's `SearchResponse` has no cursor of
/// any kind (only classic page/limit pagination), so a v3-backed `SearchResults` always leaves
/// both `nextPage`/`prevPage` nil.
///
/// v4's `multi_communities` (communities-of-communities matched by the search) and `resolve`
/// (the single federated object resolved when the query looks like a URL/AP id) fields have no
/// neutral counterpart in this phase and are omitted here -- both are out of scope until the
/// neutral surface grows a `MultiCommunity`/object-resolution vocabulary of its own.
public struct SearchResults: Sendable, Equatable {
    /// Matched posts, or empty if the search's `type` excluded posts.
    public var posts: [PostView]

    /// Matched comments, or empty if the search's `type` excluded comments.
    public var comments: [CommentView]

    /// Matched communities, or empty if the search's `type` excluded communities.
    public var communities: [CommunityView]

    /// Matched persons, or empty if the search's `type` excluded persons. Named `persons` (not
    /// v3's wire name `users`) to match the rest of this package's neutral vocabulary -- see this
    /// type's header.
    public var persons: [PersonView]

    /// A cursor to fetch the next page of results, or nil if this is the last page (always nil on
    /// a v3 backend -- see this type's header).
    public var nextPage: Cursor?

    /// A cursor to fetch the previous page of results, or nil if this is the first page (always
    /// nil on a v3 backend -- see this type's header).
    public var prevPage: Cursor?

    public init(
        posts: [PostView] = [],
        comments: [CommentView] = [],
        communities: [CommunityView] = [],
        persons: [PersonView] = [],
        nextPage: Cursor? = nil,
        prevPage: Cursor? = nil
    ) {
        self.posts = posts
        self.comments = comments
        self.communities = communities
        self.persons = persons
        self.nextPage = nextPage
        self.prevPage = prevPage
    }

    /// True if a subsequent page can be fetched via `nextPage`.
    public var hasNextPage: Bool {
        nextPage != nil
    }

    /// True if a preceding page can be fetched via `prevPage`.
    public var hasPrevPage: Bool {
        prevPage != nil
    }
}
