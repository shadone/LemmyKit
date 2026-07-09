//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.PrivateMessageView` to the neutral `PrivateMessageView` — the
/// near-direct adapter direction. v4's shape already matches the neutral one field-for-field:
/// rename snake_case to camelCase and parse the string-typed timestamps (`v4Date`/
/// `v4Date(required:)`, see `V4DateParsing.swift`) — the same pattern as
/// `CommentViewV4Mapping.swift`.
package func neutralPrivateMessageView(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.PrivateMessageView
) -> PrivateMessageView {
    PrivateMessageView(
        privateMessage: PrivateMessage(
            id: v4.private_message.id,
            creatorId: v4.private_message.creator_id,
            recipientId: v4.private_message.recipient_id,
            content: v4.private_message.content,
            deleted: v4.private_message.deleted,
            deletedByRecipient: v4.private_message.deleted_by_recipient,
            removed: v4.private_message.removed,
            local: v4.private_message.local,
            apId: v4.private_message.ap_id,
            publishedAt: v4Date(required: v4.private_message.published_at),
            updatedAt: v4Date(v4.private_message.updated_at)
        ),
        creator: neutralPerson(fromV4: v4.creator),
        recipient: neutralPerson(fromV4: v4.recipient)
    )
}
