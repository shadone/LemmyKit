//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum LikeStatus: Int32, CustomStringConvertible, Sendable {
    case liked = 1
    case disliked = -1
    case neutral = 0

    public var description: String {
        switch self {
        case .liked: return "liked"
        case .disliked: return "disliked"
        case .neutral: return "neutral"
        }
    }
}
