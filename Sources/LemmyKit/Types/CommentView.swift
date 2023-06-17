//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views/src/structs.rs

public struct CommentView: Decodable {
    /// The comment content.
    public let comment: Comment

    /// Author of the comment.
    public let creator: Person

    /// The post this comment belongs to.
    public let post: Post

    /// Community to which the comment was submitted.
    public let community: Community

    /// Stats about the comment.
    public let counts: CommentAggregates

    /// Specifies whether the comment author is banned from the community.
    public let creator_banned_from_community: Bool

    public let subscribed: SubscribedType

    /// Specifies whether the user marked the comment as saved.
    public let saved: Bool

    /// Specifies whether the user blocked the comment author.
    public let creator_blocked: Bool

    /// Users' vote status.
    public let my_vote: Int16?
}
