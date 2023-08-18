//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum ScoreAction: Int16, Encodable, CustomStringConvertible {
    case upvote = 1
    case downvote = -1
    case unvote = 0

    public var description: String {
        switch self {
        case .upvote: return "upvote"
        case .downvote: return "downvote"
        case .unvote: return "unvote"
        }
    }
}
