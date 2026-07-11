//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// One entry in a paginated private-message listing: a ``PrivateMessageView`` paired with its
/// read state.
///
/// The read flag lives here rather than on the view because the neutral ``PrivateMessageView`` has
/// **no read field** (see `PrivateMessage.swift`'s doc: v4 moved `read` off `PrivateMessage` onto
/// the wrapping notification, and the neutral shape follows v4). Returning a bare
/// `Page<PrivateMessageView>` would therefore drop read-state and regress unread indicators, so a
/// listing item pairs the view with `isRead` explicitly. `isRead` is sourced from v3's
/// `private_message.read` or v4's `notification.read` (see
/// ``LemmyApi/getPrivateMessagesNeutral(unreadOnly:pageCursor:)``).
public struct PrivateMessageListItem: Sendable, Equatable {
    /// The private message paired with its sender and recipient.
    public let view: PrivateMessageView

    /// Whether the viewer has read this message. Sourced from v3's `private_message.read` or v4's
    /// `notification.read` — not from `view`, which carries no read flag (see this type's doc).
    public let isRead: Bool

    public init(view: PrivateMessageView, isRead: Bool) {
        self.view = view
        self.isRead = isRead
    }
}
