//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct PersonMentionView: Decodable {
    public let person_mention: PersonMention
    public let comment: Comment
    public let creator: Person
    public let post: Post
    public let community: Community
    public let recipient: Person
    public let counts: CommentAggregates
    public let creator_banned_from_community: Bool
    public let subscribed: SubscribedType
    public let saved: Bool
    public let creator_blocked: Bool
    public let my_vote: Int16?
}
