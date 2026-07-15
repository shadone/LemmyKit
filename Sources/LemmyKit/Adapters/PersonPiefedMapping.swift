//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Person` for a PieFed `PiefedPerson`.
///
/// PieFed renames Lemmy's `name` to `user_name`, `display_name` to `title`, and `bot_account` to
/// `bot` (see `PiefedEntities.swift`'s header). `bio` reads `about` (the markdown source), not
/// `about_html` (its server-rendered HTML) -- matching the neutral field's documented "in
/// markdown" contract. `matrixUserId` has no PieFed source: `PiefedPerson` carries no such field
/// at all, so it is always `nil` here. Like v3's bare `Person` (the shape embedded in a
/// post/comment's `creator`), PieFed carries no post/comment tallies on this entity either -- both
/// `postCount`/`commentCount` default to `0`, matching the equivalent v3 mapping; a call site that
/// needs accurate counts must go through `neutralPersonView(fromPiefed:)`'s `PiefedPersonCounts`
/// instead.
func neutralPerson(fromPiefed person: PiefedPerson) -> Person {
    Person(
        id: person.id,
        name: person.user_name,
        displayName: person.title,
        avatarUrl: person.avatar,
        bannerUrl: person.banner,
        bio: person.about,
        apId: person.actor_id,
        matrixUserId: nil,
        botAccount: person.bot,
        deleted: person.deleted,
        local: person.local,
        publishedAt: piefedDate(person.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        postCount: 0,
        commentCount: 0
    )
}
