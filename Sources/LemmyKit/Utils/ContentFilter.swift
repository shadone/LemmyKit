//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Restricts a post or comment listing to the viewer's saved and/or voted
/// content. Vote direction is a single optional, so "liked" and "disliked"
/// are mutually exclusive and cannot be requested at the same time.
public struct ContentFilter: Hashable, Sendable {
    /// Which way the viewer voted on the content to include.
    public enum Vote: Hashable, Sendable {
        /// Only content the viewer has upvoted.
        case liked
        /// Only content the viewer has downvoted.
        case disliked
    }

    /// Include only content the viewer has saved.
    public var savedOnly: Bool
    /// Include only content the viewer voted on in this direction. `nil`
    /// imposes no vote restriction.
    public var vote: Vote?

    public init(savedOnly: Bool = false, vote: Vote? = nil) {
        self.savedOnly = savedOnly
        self.vote = vote
    }

    /// Only content the viewer has saved.
    public static let saved = ContentFilter(savedOnly: true)
    /// Only content the viewer has upvoted.
    public static let liked = ContentFilter(vote: .liked)
    /// Only content the viewer has downvoted.
    public static let disliked = ContentFilter(vote: .disliked)

    var likedOnly: Bool { vote == .liked }
    var dislikedOnly: Bool { vote == .disliked }
}
