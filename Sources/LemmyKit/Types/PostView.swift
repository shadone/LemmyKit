//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views/src/structs.rs

public struct PostView: Decodable {
    /// The post content.
    public let post: Post

    /// Author of the post.
    public let creator: Person

    /// Community to which the post was submitted.
    public let community: Community

    /// Specifies whether the post author is banned from the community.
    public let creator_banned_from_community: Bool

    /// Stats about the post.
    public let counts: PostAggregates

    public let subscribed: SubscribedType

    /// Specifies whether the user marked the post as saved.
    public let saved: Bool

    /// Specifies whether the user read the post.
    public let read: Bool

    /// Specifies whether the user blocked the post author.
    public let creator_blocked: Bool

    /// Users' vote status.
    public let my_vote: Int16?

    /// The number of unread comments in the post for the user.
    public let unread_comments: Int64
}
