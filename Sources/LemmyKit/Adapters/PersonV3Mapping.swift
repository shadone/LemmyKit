//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Person` for a v3 `Components.Schemas.Person`.
///
/// v3's bare `Person` (the shape embedded in `PostView.creator`) carries no post/comment
/// tallies -- those live on `PersonAggregates`, reachable only through a separate `PersonView`
/// (see the Phase 5 design doc's "Person details / content" section). There is no v3 source for
/// `postCount`/`commentCount` in this context, so both default to `0`; a call site that needs
/// accurate counts must go through `personDetails` instead, not this mapping.
func neutralPerson(fromV3 person: Components.Schemas.Person) -> Person {
    Person(
        id: Int64(person.id),
        name: person.name,
        displayName: person.display_name,
        avatarUrl: person.avatar,
        bannerUrl: person.banner,
        bio: person.bio,
        apId: person.actor_id,
        matrixUserId: person.matrix_user_id,
        botAccount: person.bot_account,
        deleted: person.deleted,
        local: person.local,
        publishedAt: person.published,
        updatedAt: person.updated,
        postCount: 0,
        commentCount: 0
    )
}
