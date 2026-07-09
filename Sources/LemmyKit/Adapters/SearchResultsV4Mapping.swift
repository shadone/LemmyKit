//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.SearchResponse` to the neutral `SearchResults` -- the
/// near-direct adapter direction (see `PostViewV4Mapping.swift`'s header for the general shape of
/// this direction), reusing the existing per-item view mappers for each of the four result
/// arrays, and wrapping the response's own `next_page`/`prev_page` cursors via
/// `neutralCursor(fromV4:)`.
///
/// v4's `multi_communities` and `resolve` fields have no neutral counterpart in this phase -- see
/// `Neutral/SearchResults.swift`'s header -- and are dropped.
package func neutralSearchResults(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.SearchResponse
) -> SearchResults {
    SearchResults(
        posts: v4.posts.map { neutralPostView(fromV4: $0) },
        comments: v4.comments.map { neutralCommentView(fromV4: $0) },
        communities: v4.communities.map { neutralCommunityView(fromV4: $0) },
        persons: v4.persons.map { neutralPersonView(fromV4: $0) },
        nextPage: neutralCursor(fromV4: v4.next_page),
        prevPage: neutralCursor(fromV4: v4.prev_page)
    )
}
