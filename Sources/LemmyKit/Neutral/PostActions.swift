//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's relationship to a single post: read/hidden/saved state, vote, and
/// the account's last-seen point in the comment thread.
///
/// This mirrors v4's `post_actions` object. v4 encodes each boolean as the *timestamp* of when
/// the action happened (`nil` means "never happened"); v3 has no such timestamps, so a v3
/// backend adapter leaves the `*At` fields `nil` even when the underlying state is known (e.g.
/// v3's bare `saved: Bool` maps to `isSaved` via a derived property, not by inventing a
/// timestamp). Call sites should read the derived `is*`/`vote` properties, never the raw
/// timestamps, so they work the same regardless of which backend produced the value.
public struct PostActions: Sendable, Equatable {
    /// When the account marked the post read, or `nil` if unread (v3: timestamp unknown, so
    /// this is `nil` even when the post is in fact read — see `isRead`).
    public var readAt: Date?

    /// When the account hid the post from their feeds, or `nil` if not hidden.
    public var hiddenAt: Date?

    /// When the account saved the post, or `nil` if not saved.
    public var savedAt: Date?

    /// When the account cast a vote on the post, or `nil` if no vote has ever been cast. Pairs
    /// with `voteIsUpvote` to determine `vote`; see `VoteDirection.fromV4(votedAt:isUpvote:)`.
    public var votedAt: Date?

    /// The direction of the vote named by `votedAt`: `true` for an upvote, `false` for a
    /// downvote. Meaningless when `votedAt` is `nil`.
    public var voteIsUpvote: Bool?

    /// When the account last read into the post's comment thread, or `nil` if never opened.
    public var readCommentsAt: Date?

    /// How many top-level-order comments the account had seen as of `readCommentsAt`. Used
    /// alongside the post's total comment count to derive an "N new comments" badge.
    public var readCommentsAmount: Int64?

    /// Creates a set of per-viewer post actions. All parameters default to `nil` ("not done"),
    /// which is also the correct value for a signed-out viewer or a post the account has never
    /// interacted with.
    public init(
        readAt: Date? = nil,
        hiddenAt: Date? = nil,
        savedAt: Date? = nil,
        votedAt: Date? = nil,
        voteIsUpvote: Bool? = nil,
        readCommentsAt: Date? = nil,
        readCommentsAmount: Int64? = nil
    ) {
        self.readAt = readAt
        self.hiddenAt = hiddenAt
        self.savedAt = savedAt
        self.votedAt = votedAt
        self.voteIsUpvote = voteIsUpvote
        self.readCommentsAt = readCommentsAt
        self.readCommentsAmount = readCommentsAmount
    }

    /// Whether the account has read the post. `true` iff `readAt` is set.
    public var isRead: Bool { readAt != nil }

    /// Whether the account has hidden the post. `true` iff `hiddenAt` is set.
    public var isHidden: Bool { hiddenAt != nil }

    /// Whether the account has saved the post. `true` iff `savedAt` is set.
    public var isSaved: Bool { savedAt != nil }

    /// The account's vote on the post, derived from `votedAt`/`voteIsUpvote`. `.none` when
    /// `votedAt` is `nil` (no vote cast), regardless of `voteIsUpvote`.
    public var vote: VoteDirection { VoteDirection.fromV4(votedAt: votedAt, isUpvote: voteIsUpvote) }
}
