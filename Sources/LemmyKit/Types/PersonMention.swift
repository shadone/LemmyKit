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
}
