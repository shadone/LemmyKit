//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The metadata of one entry in the unified notification inbox, decoupled from the generated
/// OpenAPI schema. Paired with its payload in ``NotificationView``.
///
/// Mirrors v4's `Notification` schema. See
/// ``LemmyApi/listNotificationsNeutral(unreadOnly:pageCursor:)`` for how a v3 backend synthesizes
/// this by fanning out and merging its three separate endpoints.
public struct Notification: Sendable, Equatable {
    /// The server-assigned notification id, or `nil` on a v3-backed notification.
    ///
    /// v3 has no unified notification id: each of its three sources (`getReplies`,
    /// `getPersonMentions`, `getPrivateMessages`) has its own disjoint id space
    /// (`CommentReplyID`/`PersonMentionID`/`PrivateMessageID` respectively), none of which is a
    /// cross-kind identity that could serve as this field. The V3 adapter therefore always
    /// leaves this `nil` when fanning those three endpoints out and merging them (see
    /// `CommentReplyNotificationV3Mapping.swift` and its siblings). A v4-backed `Notification`
    /// always has one, taken directly from `notification.id`.
    public let id: Int64?

    /// Which kind of notification this is.
    public let kind: NotificationKind

    /// Whether the recipient has already read this notification.
    public let isRead: Bool

    /// When the notification's underlying activity occurred, or `nil` if unavailable.
    public let publishedAt: Date?

    public init(id: Int64?, kind: NotificationKind, isRead: Bool, publishedAt: Date?) {
        self.id = id
        self.kind = kind
        self.isRead = isRead
        self.publishedAt = publishedAt
    }
}
