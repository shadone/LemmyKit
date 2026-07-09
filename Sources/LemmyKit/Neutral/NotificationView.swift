//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A single entry in the unified notification inbox, decoupled from the generated OpenAPI schema.
///
/// Mirrors v4's `NotificationView`. See
/// ``LemmyApi/listNotificationsNeutral(unreadOnly:pageCursor:)`` for how a v3 backend synthesizes
/// this list by fanning out and merging its three separate endpoints.
public struct NotificationView: Sendable, Equatable {
    /// The notification's metadata (kind, read state, id, timestamp).
    public var notification: NotificationEntry

    /// The notification's payload.
    public var data: NotificationData

    public init(notification: NotificationEntry, data: NotificationData) {
        self.notification = notification
        self.data = data
    }
}
