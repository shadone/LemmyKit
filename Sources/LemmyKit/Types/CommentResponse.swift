//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CommentResponse: Decodable {
    public let comment_view: CommentView

    public let recipient_ids: [LocalUserId]

    public init(
        comment_view: CommentView,
        recipient_ids: [LocalUserId]
    ) {
        self.comment_view = comment_view
        self.recipient_ids = recipient_ids
    }
}
