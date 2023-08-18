//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct PersonMention: Decodable {
    public let id: PersonMentionId
    public let recipient_id: PersonId
    public let comment_id: CommentId
    public let read: Bool
    public let published: Date

    public init(
        id: PersonMentionId,
        recipient_id: PersonId,
        comment_id: CommentId,
        read: Bool,
        published: Date
    ) {
        self.id = id
        self.recipient_id = recipient_id
        self.comment_id = comment_id
        self.read = read
        self.published = published
    }
}
