//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `Person` for a v4 `Components.Schemas.Person`.
///
/// v4 already flattens `post_count`/`comment_count` directly onto `Person`, matching the
/// neutral shape 1:1 -- unlike v3, whose bare `Person` has no tallies at all (see
/// `PersonV3Mapping.swift`).
func neutralPerson(fromV4 person: LemmyKitV4Generated.Components.Schemas.Person) -> Person {
    Person(
        id: person.id,
        name: person.name,
        displayName: person.display_name,
        avatarUrl: person.avatar,
        bannerUrl: person.banner,
        bio: person.bio,
        apId: person.ap_id,
        matrixUserId: person.matrix_user_id,
        botAccount: person.bot_account,
        deleted: person.deleted,
        local: person.local,
        publishedAt: v4Date(required: person.published_at),
        updatedAt: v4Date(person.updated_at),
        postCount: person.post_count,
        commentCount: person.comment_count
    )
}
