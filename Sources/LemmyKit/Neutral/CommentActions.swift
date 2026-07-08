//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's relationship to a single comment: saved state and vote.
///
/// This mirrors v4's `comment_actions` object, the smaller sibling of `PostActions` (comments
/// have no read/hidden state or comment-thread cursor). As with `PostActions`, v4 encodes each
/// boolean as a timestamp (`nil` means "never happened"); a v3 backend adapter has no such
/// timestamps and leaves the `*At` fields `nil` even when the underlying state is known. Call
/// sites should read the derived `isSaved`/`vote` properties, never the raw timestamps.
public struct CommentActions: Sendable, Equatable {
    /// When the account saved the comment, or `nil` if not saved.
    public var savedAt: Date?

    /// When the account cast a vote on the comment, or `nil` if no vote has ever been cast.
    /// Pairs with `voteIsUpvote` to determine `vote`; see
    /// `VoteDirection.fromV4(votedAt:isUpvote:)`.
    public var votedAt: Date?

    /// The direction of the vote named by `votedAt`: `true` for an upvote, `false` for a
    /// downvote. Meaningless when `votedAt` is `nil`.
    public var voteIsUpvote: Bool?

    /// Creates a set of per-viewer comment actions. All parameters default to `nil` ("not
    /// done"), which is also the correct value for a signed-out viewer or a comment the account
    /// has never interacted with.
    public init(
        savedAt: Date? = nil,
        votedAt: Date? = nil,
        voteIsUpvote: Bool? = nil
    ) {
        self.savedAt = savedAt
        self.votedAt = votedAt
        self.voteIsUpvote = voteIsUpvote
    }

    /// Whether the account has saved the comment. `true` iff `savedAt` is set.
    public var isSaved: Bool { savedAt != nil }

    /// The account's vote on the comment, derived from `votedAt`/`voteIsUpvote`. `.none` when
    /// `votedAt` is `nil` (no vote cast), regardless of `voteIsUpvote`.
    public var vote: VoteDirection { VoteDirection.fromV4(votedAt: votedAt, isUpvote: voteIsUpvote) }
}
