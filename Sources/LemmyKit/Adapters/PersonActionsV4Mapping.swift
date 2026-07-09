//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps v4's `person_actions` object to the neutral `PersonActions`, field-by-field. Shared by
/// the v4 `PostView` and `CommentView` adapters -- both views carry an optional `person_actions`
/// of this exact generated type.
///
/// v4's vote-tally fields (`upvotes`/`downvotes`, aggregate votes this viewer has cast on the
/// person) have no neutral counterpart -- see `Neutral/PersonActions.swift`'s header (dropped
/// per YAGNI) -- and are dropped here too.
func neutralPersonActions(
    fromV4 actions: LemmyKitV4Generated.Components.Schemas.PersonActions
) -> PersonActions {
    PersonActions(
        blockedAt: v4Date(actions.blocked_at),
        note: actions.note,
        notedAt: v4Date(actions.noted_at)
    )
}
