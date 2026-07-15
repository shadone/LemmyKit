//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedSearchResponse` to the neutral, v4-shaped `SearchResults` -- the "emulate
/// upward" adapter direction, the same pattern as `SearchResultsV3Mapping.swift`, reusing the
/// existing per-item view mappers for each of the four result arrays.
///
/// PieFed's `PiefedSearchResponse` names its person-result array `users`; the neutral (v4-shaped)
/// type calls it `persons` to match the rest of this package's neutral vocabulary -- this adapter
/// is the rename point, same as v3. PieFed's `PiefedSearchResponse` carries no pagination cursor
/// of any kind (only classic page/limit, mirroring v3), so `nextPage`/`prevPage` are always nil
/// here.
package func neutralSearchResults(fromPiefed response: PiefedSearchResponse) -> SearchResults {
    SearchResults(
        posts: response.posts.map { neutralPostView(fromPiefed: $0) },
        comments: response.comments.map { neutralCommentView(fromPiefed: $0) },
        communities: response.communities.map { neutralCommunityView(fromPiefed: $0) },
        persons: response.users.map { neutralPersonView(fromPiefed: $0) },
        nextPage: nil,
        prevPage: nil
    )
}
