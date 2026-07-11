//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// The version-neutral unread-count summary for the signed-in account's unified inbox.
///
/// v3 and v4 report unread counts in incompatible shapes, so this type carries both a
/// backend-agnostic ``total`` and the v3-only per-kind breakdown, rather than picking one shape
/// and dropping information the other backend has:
/// - v4's `GetUnreadCounts` reports a single `notification_count` covering every notification
///   kind in the unified inbox (plus admin/mod-only counts this type doesn't surface). There is
///   no per-kind breakdown to recover, so ``replies``, ``mentions``, and ``privateMessages`` are
///   all nil on a v4-backed result.
/// - v3's `getUnreadCount` reports `replies`/`mentions`/`private_messages` as three separate
///   counts with no combined total. ``total`` is synthesized by summing the three.
///
/// See ``LemmyApi/unreadCountsNeutral()``.
public struct UnreadCounts: Sendable, Equatable {
    /// The total number of unread notifications. Always present: v4's own `notification_count`,
    /// or the sum of v3's three per-kind counts.
    public let total: Int64

    /// The number of unread replies, or nil on a v4-backed result (see this type's doc).
    public let replies: Int64?

    /// The number of unread mentions, or nil on a v4-backed result (see this type's doc).
    public let mentions: Int64?

    /// The number of unread private messages, or nil on a v4-backed result (see this type's doc).
    public let privateMessages: Int64?

    public init(total: Int64, replies: Int64?, mentions: Int64?, privateMessages: Int64?) {
        self.total = total
        self.replies = replies
        self.mentions = mentions
        self.privateMessages = privateMessages
    }
}
