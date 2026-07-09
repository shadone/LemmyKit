//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.SearchResponse` to the neutral, v4-shaped `SearchResults` --
/// the "emulate upward" adapter direction (see `PostViewV3Mapping.swift`'s header for the general
/// shape of this direction), reusing the existing per-item view mappers for each of the four
/// result arrays.
///
/// v3's `SearchResponse` names its person-result array `users`; the neutral (v4-shaped) type
/// calls it `persons` to match the rest of this package's neutral vocabulary (`PersonView`,
/// `Person`) -- this adapter is the rename point (see `Neutral/SearchResults.swift`'s header).
/// v3's `SearchResponse` carries no pagination cursor of any kind (only classic page/limit, see
/// `LemmyApi+SearchNeutral.swift`), so `nextPage`/`prevPage` are always nil here.
package func neutralSearchResults(fromV3 v3: Components.Schemas.SearchResponse) -> SearchResults {
    SearchResults(
        posts: v3.posts.map { neutralPostView(fromV3: $0) },
        comments: v3.comments.map { neutralCommentView(fromV3: $0) },
        communities: v3.communities.map { neutralCommunityView(fromV3: $0) },
        persons: v3.users.map { neutralPersonView(fromV3: $0) },
        nextPage: nil,
        prevPage: nil
    )
}
