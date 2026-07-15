//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedPersonView` (as returned in `GetSiteResponse.admins` and
/// `SearchResponse.users`) to the neutral `PersonView` -- the "emulate upward" adapter direction,
/// the same pattern as `PersonViewV3Mapping.swift`.
///
/// PieFed's `PiefedPersonView` carries a `PiefedPersonCounts` (`counts`) with exact
/// `post_count`/`comment_count` tallies, mapped straight across to the neutral view's
/// `postCount`/`commentCount`, same as v3. Unlike v3 (whose `PersonView` has no ban-standing field
/// at all, so `isBanned` is always `false`), PieFed's underlying `PiefedPerson.banned` DOES carry
/// a real ban flag, so this reads it directly rather than hardcoding `false` -- a PieFed-only
/// improvement over the v3 emulation gap it otherwise mirrors. No per-viewer relationship to the
/// person is exposed on this view either, so `personActions` is always `nil`, same as v3.
package func neutralPersonView(fromPiefed view: PiefedPersonView) -> PersonView {
    PersonView(
        person: neutralPerson(fromPiefed: view.person),
        isAdmin: view.is_admin,
        isBanned: view.person.banned,
        personActions: nil,
        postCount: view.counts.post_count,
        commentCount: view.counts.comment_count
    )
}
