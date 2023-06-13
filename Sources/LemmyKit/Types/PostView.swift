//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views/src/structs.rs

public struct PostView: Decodable {
    public let post: Post
    public let creator: Person
    public let community: Community
    public let creator_banned_from_community: Bool
    public let counts: PostAggregates
    public let subscribed: SubscribedType
    public let saved: Bool
    public let read: Bool
    public let creator_blocked: Bool
    public let my_vote: Int16?
    public let unread_comments: Int64
}
