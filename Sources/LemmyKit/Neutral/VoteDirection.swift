//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's vote on a post or comment, independent of backend wire shape.
///
/// v4 represents a vote as an optional boolean (`is_upvote`); v3 represents it as a signed
/// score (`my_vote`: 1, -1, or 0/absent). `VoteDirection` is the neutral value both backends
/// read from and write to; the computed properties and static readers below are the mapping
/// helpers the V3/V4 adapters use to convert in each direction.
public enum VoteDirection: Sendable, Equatable {
    /// An upvote.
    case up

    /// A downvote.
    case down

    /// No vote cast (or a previous vote retracted).
    case none

    /// The v4 wire representation: `true` for an upvote, `false` for a downvote, `nil` for no
    /// vote. Used by the V4 adapter when writing `is_upvote` on a vote request.
    public var v4IsUpvote: Bool? {
        switch self {
        case .up:
            true
        case .down:
            false
        case .none:
            nil
        }
    }

    /// The v3 wire representation: a signed score, `1` for an upvote, `-1` for a downvote, `0`
    /// for no vote. Used by the V3 adapter when writing `score` on a `CreatePostLike`/
    /// `CreateCommentLike` request.
    public var v3Score: Int {
        switch self {
        case .up:
            1
        case .down:
            -1
        case .none:
            0
        }
    }

    /// Reads a `VoteDirection` back from a v3 `my_vote` score. Any positive score reads as
    /// `.up`, any negative score reads as `.down`, and zero or a missing value (the field is
    /// absent when the account has never voted) reads as `.none`.
    public static func fromV3Score(_ score: Int?) -> VoteDirection {
        guard let score else { return .none }
        if score > 0 {
            return .up
        } else if score < 0 {
            return .down
        } else {
            return .none
        }
    }

    /// Reads a `VoteDirection` back from the v4 `post_actions`/`comment_actions` pair of
    /// `voted_at` (when the vote was cast) and `is_upvote` (its direction). A nil `votedAt`
    /// means no vote exists at all, regardless of `isUpvote`; otherwise the direction follows
    /// `isUpvote` (`true` → `.up`, `false` → `.down`, `nil` → `.none`, though v4 should not
    /// produce a non-nil `votedAt` paired with a nil `isUpvote` in practice).
    public static func fromV4(votedAt: Date?, isUpvote: Bool?) -> VoteDirection {
        guard votedAt != nil else { return .none }
        switch isUpvote {
        case true:
            return .up
        case false:
            return .down
        case nil:
            return .none
        }
    }
}
