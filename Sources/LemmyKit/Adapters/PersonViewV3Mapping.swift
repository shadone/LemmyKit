//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.PersonView` (as returned by `getPersonDetails`) to the neutral
/// `PersonView` -- the "emulate upward" adapter direction (see `Neutral/PersonView.swift`'s
/// header).
///
/// v3's `PersonView` carries a `PersonAggregates` (`counts`) with exact `post_count`/
/// `comment_count` tallies, mapped straight across to the neutral view's `postCount`/
/// `commentCount`. v3 has no ban-standing field on this view at all, so `isBanned` is always
/// `false`, and no per-viewer relationship to the person is exposed here either, so
/// `personActions` is always `nil` -- see `Neutral/PersonView.swift`'s header for both gaps.
func neutralPersonView(fromV3 v3: Components.Schemas.PersonView) -> PersonView {
    PersonView(
        person: neutralPerson(fromV3: v3.person),
        isAdmin: v3.is_admin,
        isBanned: false,
        personActions: nil,
        postCount: v3.counts.post_count,
        commentCount: v3.counts.comment_count
    )
}
