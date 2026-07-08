//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's relationship to another person: block state and a private note.
///
/// This mirrors v4's `person_actions` object, minus its vote-tally fields (aggregate counts of
/// upvotes/downvotes the account has given that person) — Spud has no use for those, so they
/// are omitted here per YAGNI; add them back if a consumer needs them. As with the other action
/// structs, v4 encodes booleans as timestamps (`nil` means "never happened"); a v3 backend
/// adapter has no such timestamp and leaves `blockedAt` `nil` even when the block is known (v3
/// exposes blocking as a bare `Bool` on the relevant view, e.g. `creator_blocked`). Call sites
/// should read `isBlocked`, never the raw timestamp.
public struct PersonActions: Sendable, Equatable {
    /// When the account blocked this person, or `nil` if not blocked.
    public var blockedAt: Date?

    /// A private note the account has attached to this person, or `nil` if none.
    public var note: String?

    /// When the note was last set, or `nil` if there is no note.
    public var notedAt: Date?

    /// Creates a set of per-viewer person actions. All parameters default to `nil` ("not
    /// done"), which is also the correct value for a signed-out viewer or a person the account
    /// has no relationship with.
    public init(
        blockedAt: Date? = nil,
        note: String? = nil,
        notedAt: Date? = nil
    ) {
        self.blockedAt = blockedAt
        self.note = note
        self.notedAt = notedAt
    }

    /// Whether the account has blocked this person. `true` iff `blockedAt` is set.
    public var isBlocked: Bool { blockedAt != nil }
}
