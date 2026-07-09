//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A person's profile and moderation standing, decoupled from the generated OpenAPI schema.
///
/// Returned by ``LemmyApi/personDetailsNeutral(personId:)``. v4 splits a person's profile
/// (`GetPersonDetails`) from their post/comment feed (`ListPersonContent`, see
/// ``LemmyApi/personContentNeutral(personId:pageCursor:)``); this type mirrors that split -- it
/// carries no posts/comments of its own, even on a v3 backend, whose single `getPersonDetails`
/// call returns both inline (see `personContentNeutral`'s doc for how the v3 adapter recovers the
/// combined feed from that same call).
public struct PersonDetails: Sendable, Equatable {
    /// The person's profile, admin/ban standing, and viewer relationship.
    public var personView: PersonView

    /// The ids of the communities this person moderates.
    public var moderates: [Int64]

    public init(personView: PersonView, moderates: [Int64]) {
        self.personView = personView
        self.moderates = moderates
    }
}
