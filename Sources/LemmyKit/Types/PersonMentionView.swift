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
    public let creator_is_moderator: Bool
    public let creator_is_admin: Bool
    public let subscribed: SubscribedType
    public let saved: Bool
    public let creator_blocked: Bool
    public let my_vote: Int16?

    public init(
        person_mention: PersonMention,
        comment: Comment,
        creator: Person,
        post: Post,
        community: Community,
        recipient: Person,
        counts: CommentAggregates,
        creator_banned_from_community: Bool,
        creator_is_moderator: Bool,
        creator_is_admin: Bool,
        subscribed: SubscribedType,
        saved: Bool,
        creator_blocked: Bool,
        my_vote: Int16? = nil
    ) {
        self.person_mention = person_mention
        self.comment = comment
        self.creator = creator
        self.post = post
        self.community = community
        self.recipient = recipient
        self.counts = counts
        self.creator_banned_from_community = creator_banned_from_community
        self.creator_is_moderator = creator_is_moderator
        self.creator_is_admin = creator_is_admin
        self.subscribed = subscribed
        self.saved = saved
        self.creator_blocked = creator_blocked
        self.my_vote = my_vote
    }
}
