//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum ScoreAction: Int16, Encodable {
    case upvote = 1
    case downvote = -1
    case unvote = 0
}
