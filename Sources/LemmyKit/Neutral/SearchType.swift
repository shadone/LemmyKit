//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// Which kind of result a search should return.
///
/// This is v4-shaped, but only loosely -- v3 and v4 diverge on this filter in both directions.
/// v4 dropped v3's `.url` case (a "match only link posts whose url matches the query" filter,
/// superseded on v4 by the separate `post_url_only` boolean, which this neutral surface does not
/// yet expose), and added `.multiCommunities` (out of scope for this phase, matching the omission
/// of `SearchResults.multiCommunities` -- see that type's header). Neither is represented here, so
/// this enum only covers the shared ground both backends agree on.
///
/// Both v3 and v4 spell the "persons" case of this filter "Users"/"users" on the wire (unlike
/// `SearchResponse`'s result array, which v4 renamed to `persons`); the neutral case is named
/// `.persons` regardless, to match the rest of this package's neutral vocabulary (`PersonView`,
/// `Person`).
public enum SearchType: Sendable, Equatable, CaseIterable {
    /// Every kind of result (posts, comments, communities, persons).
    case all

    /// Only comments.
    case comments

    /// Only posts.
    case posts

    /// Only communities.
    case communities

    /// Only persons.
    case persons
}
