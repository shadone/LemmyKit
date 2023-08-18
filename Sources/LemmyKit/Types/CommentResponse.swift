//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CommentResponse: Decodable {
    public let comment_view: CommentView

    public let recipient_ids: [LocalUserId]

    /// An optional front end ID, to tell which is coming back
    public let form_id: String?

    public init(
        comment_view: CommentView,
        recipient_ids: [LocalUserId],
        form_id: String? = nil
    ) {
        self.comment_view = comment_view
        self.recipient_ids = recipient_ids
        self.form_id = form_id
    }
}
