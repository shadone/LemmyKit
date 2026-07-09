//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.PrivateMessageView` to the neutral, v4-shaped
/// `PrivateMessageView` — the "emulate upward" adapter direction (see `PrivateMessage.swift`'s
/// doc for the neutral shape and why it has no `isRead`).
///
/// v3's `PrivateMessage.read` is dropped here, not carried onto the neutral `PrivateMessage` —
/// see that type's doc for why (it feeds `Notification.isRead` instead, at the call site in
/// `PrivateMessageNotificationV3Mapping.swift`). `deletedByRecipient`/`removed` have no v3 source
/// and default to `false`, the same "defaults to 0, no v3 source" pattern as
/// `PersonV3Mapping.swift`'s post/comment counts.
package func neutralPrivateMessageView(fromV3 v3: Components.Schemas.PrivateMessageView) -> PrivateMessageView {
    PrivateMessageView(
        privateMessage: PrivateMessage(
            id: Int64(v3.private_message.id),
            creatorId: Int64(v3.private_message.creator_id),
            recipientId: Int64(v3.private_message.recipient_id),
            content: v3.private_message.content,
            deleted: v3.private_message.deleted,
            deletedByRecipient: false,
            removed: false,
            local: v3.private_message.local,
            apId: v3.private_message.ap_id,
            publishedAt: v3.private_message.published,
            updatedAt: v3.private_message.updated
        ),
        creator: neutralPerson(fromV3: v3.creator),
        recipient: neutralPerson(fromV3: v3.recipient)
    )
}
