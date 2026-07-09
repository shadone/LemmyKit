//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A person as returned by a person-details lookup: the bare `Person` composed with admin/ban
/// standing and the viewer's per-viewer relationship to them, decoupled from the generated
/// OpenAPI schema.
///
/// This mirrors v4's person-details `PersonView` (`GetPersonDetailsResponse.person_view`) --
/// admin/ban standing lives here rather than on the bare `Person`, matching v4's own split (see
/// `Neutral/Person.swift`'s header, which keeps those "per-viewing-context flags" off the bare
/// person). A V3 backend adapter derives `isAdmin` from v3's own `PersonView.is_admin`, but v3
/// has no ban-standing field on this view at all, so `isBanned` always comes back `false` there
/// (see `isBanned`'s doc below).
///
/// `postCount`/`commentCount` are v3-only: v3's `PersonView` carries a `PersonAggregates`
/// (`counts`) with exact tallies, but v4 dropped that struct entirely when it flattened
/// `post_count`/`comment_count` directly onto the bare `Person` (see `Neutral/Person.swift`) --
/// so a v4-backed `PersonView` always leaves both `nil` here; read `person.postCount`/
/// `person.commentCount` instead on that backend.
public struct PersonView: Sendable, Equatable {
    /// The person being viewed.
    public var person: Person

    /// Whether the person is an administrator of the instance being viewed from.
    public var isAdmin: Bool

    /// Whether the person is banned instance-wide. Always `false` on a v3 backend -- v3's
    /// `PersonView` carries no ban-standing field to read this from.
    public var isBanned: Bool

    /// The viewer's per-viewer relationship to this person (block state), or `nil` for a
    /// signed-out viewer, a person never interacted with, or a v3 backend (whose person-details
    /// response carries no such relationship at all).
    public var personActions: PersonActions?

    /// The number of posts the person has made, or `nil` on a v4 backend (see the type's
    /// header).
    public var postCount: Int64?

    /// The number of comments the person has made, or `nil` on a v4 backend (see the type's
    /// header).
    public var commentCount: Int64?

    public init(
        person: Person,
        isAdmin: Bool,
        isBanned: Bool = false,
        personActions: PersonActions? = nil,
        postCount: Int64? = nil,
        commentCount: Int64? = nil
    ) {
        self.person = person
        self.isAdmin = isAdmin
        self.isBanned = isBanned
        self.personActions = personActions
        self.postCount = postCount
        self.commentCount = commentCount
    }

    /// Whether the viewer has blocked this person. `false` when `personActions` is `nil`.
    public var isBlocked: Bool { personActions?.isBlocked ?? false }
}
