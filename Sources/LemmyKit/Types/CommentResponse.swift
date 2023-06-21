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
}
