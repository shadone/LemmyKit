//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The vote a user has cast on a post or comment.
///
/// The raw value matches the score the vote contributes: `1`, `-1`, or `0`.
public enum LikeStatus: Int32, CustomStringConvertible, Sendable {
    /// An upvote (raw value `1`).
    case liked = 1
    /// A downvote (raw value `-1`).
    case disliked = -1
    /// No vote, or removal of an existing vote (raw value `0`).
    case neutral = 0

    /// A lowercase label for the vote: `"liked"`, `"disliked"`, or `"neutral"`.
    public var description: String {
        switch self {
        case .liked: "liked"
        case .disliked: "disliked"
        case .neutral: "neutral"
        }
    }
}
