//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps one item of v3's `getPrivateMessages` response to a full neutral `NotificationView` — one
/// leg of the three-way fan-out ``LemmyApi/listNotificationsNeutral(unreadOnly:pageCursor:)``'s
/// v3 path merges (see that method's doc).
///
/// Unlike the reply/mention legs (`CommentReplyNotificationV3Mapping.swift`/
/// `PersonMentionNotificationV3Mapping.swift`), v3's `PrivateMessageView` needs no field-set
/// reconstruction — `neutralPrivateMessageView(fromV3:)` already maps it directly.
package func neutralNotificationView(fromV3PrivateMessage pm: Components.Schemas.PrivateMessageView) -> NotificationView {
    NotificationView(
        notification: NotificationEntry(
            id: nil,
            kind: .privateMessage,
            isRead: pm.private_message.read,
            publishedAt: pm.private_message.published
        ),
        data: .privateMessage(neutralPrivateMessageView(fromV3: pm))
    )
}
