//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum Filter: Hashable, Sendable {
    public enum LikeFilter: Hashable, Sendable {
        /// Filter only `liked` (upvoted) posts.
        case liked
        /// Filter only `disliked` (downvoted) posts.
        case disliked
    }

    /// The filter set for only saved posts.
    case saved
    /// The filter set for liked or disliked posts.
    case like(LikeFilter)

    /// Filter only `liked` (upvoted) posts.
    public static let liked = Filter.like(.liked)
    /// Filter only `disliked` (downvoted) posts.
    public static let disliked = Filter.like(.disliked)

    /// Return true if the filter is set for only saved posts.
    var isSaved: Bool {
        if case .saved = self {
            return true
        }
        return false
    }

    /// Return true if the filter is set for only liked posts.
    var isLiked: Bool {
        if case .like(.liked) = self {
            return true
        }
        return false
    }

    /// Return true if the filter is set for only disliked posts.
    var isDisliked: Bool {
        if case .like(.disliked) = self {
            return true
        }
        return false
    }
}
