//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.PersonView` (as returned by `GetPersonDetails`) to the neutral
/// `PersonView` -- the near-direct adapter direction (see `Neutral/PersonView.swift`'s header).
///
/// v4 dropped `PersonAggregates` when it flattened `post_count`/`comment_count` onto the bare
/// `Person` (see `PersonV4Mapping.swift`), so `postCount`/`commentCount` are always `nil` here --
/// read `person.postCount`/`person.commentCount` off the mapped `Person` instead.
///
/// v4's `ban_expires_at` (when the ban lifts) has no neutral counterpart yet -- only the bare
/// `banned` flag is carried across, as `isBanned` -- and is dropped.
func neutralPersonView(fromV4 v4: LemmyKitV4Generated.Components.Schemas.PersonView) -> PersonView {
    PersonView(
        person: neutralPerson(fromV4: v4.person),
        isAdmin: v4.is_admin,
        isBanned: v4.banned,
        personActions: v4.person_actions.map(neutralPersonActions(fromV4:)),
        postCount: nil,
        commentCount: nil
    )
}
