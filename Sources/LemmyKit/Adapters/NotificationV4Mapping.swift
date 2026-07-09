//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// A v4 `NotificationData` decoded with none of its four `anyOf` payloads present.
///
/// Mirrors `PostCommentCombinedViewError` (see `PostCommentCombinedV4Mapping.swift`'s doc) for
/// v4's `NotificationData`, which the generator represents the same way — four independent
/// optional payloads (`value1`...`value4`, one per notification kind that carries a payload:
/// comment/post/private_message/mod_action — `.subscribed` carries no payload at all, see
/// `NotificationData`'s doc). The generator's own `verifyAtLeastOneSchemaIsNotNil` guarantees at
/// least one decodes — seeing none here would mean that invariant was violated, which should
/// never happen in practice.
enum NotificationDataError: Error, Equatable {
    case noBranchPresent
}

/// Maps a v4 `Components.Schemas.NotificationView` to the neutral `NotificationView` — the
/// near-direct adapter direction (see the Phase 5 design doc's "Notifications" section).
///
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``NotificationDataError/noBranchPresent`` if
///   somehow none of `data`'s four `anyOf` payloads decoded (see that error's doc — not expected
///   in practice).
package func neutralNotificationView(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.NotificationView
) throws -> NotificationView {
    try NotificationView(
        notification: neutralNotification(fromV4: v4.notification),
        data: neutralNotificationData(fromV4: v4.data)
    )
}

/// Maps v4's `Notification` metadata to the neutral `Notification`. Unlike a v3-synthesized
/// notification (see `CommentReplyNotificationV3Mapping.swift` and its siblings), v4 always
/// supplies a real `id` — see `Notification.id`'s doc.
private func neutralNotification(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.Notification
) -> Notification {
    Notification(
        id: v4.id,
        kind: neutralNotificationKind(fromV4: v4.kind),
        isRead: v4.read,
        publishedAt: v4Date(v4.published_at)
    )
}

/// Maps v4's `NotificationType` to the neutral `NotificationKind`, a straight case-for-case
/// rename (see `NotificationKind`'s doc for which kinds have a v3 source).
private func neutralNotificationKind(
    fromV4 kind: LemmyKitV4Generated.Components.Schemas.NotificationType
) -> NotificationKind {
    switch kind {
    case .mention: .mention
    case .reply: .reply
    case .subscribed: .subscribed
    case .private_message: .privateMessage
    case .mod_action: .modAction
    }
}

/// Maps v4's `NotificationData` `anyOf` to the neutral `NotificationData`, switching on which of
/// the generator's four independent payloads decoded — `value1`/`value2`/`value3`/`value4` are
/// checked in the order the spec lists them (`comment`, `post`, `private_message`, `mod_action`);
/// in practice they're mutually exclusive, since each requires a different literal `type_`.
/// `value4` (the `mod_action` branch) carries a `ModlogView` that is deliberately ignored — see
/// `NotificationData.modAction`'s doc for why.
private func neutralNotificationData(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.NotificationData
) throws -> NotificationData {
    if let comment = v4.value1 {
        return .comment(neutralCommentView(fromV4: comment.value2))
    }
    if let post = v4.value2 {
        return .post(neutralPostView(fromV4: post.value2))
    }
    if let privateMessage = v4.value3 {
        return .privateMessage(neutralPrivateMessageView(fromV4: privateMessage.value2))
    }
    if v4.value4 != nil {
        return .modAction
    }
    throw LemmyApiError.unknown(NotificationDataError.noBranchPresent)
}
