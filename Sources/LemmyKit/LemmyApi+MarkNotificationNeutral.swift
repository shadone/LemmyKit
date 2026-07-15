//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Marks a single unified-inbox notification as read or unread.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). On v4 this calls `MarkNotificationAsRead` with `id` directly, since v4
    /// notifications carry a real, unified id. On v3 this is a documented no-op — see this
    /// method's v3 note.
    ///
    /// - Parameters:
    ///   - id: the notification to update. On v4 this is the id from that notification's
    ///     ``NotificationEntry/id``.
    ///   - read: true to mark as read, false to mark as unread.
    /// - Note: On v3, `id` has no meaning: ``listNotificationsNeutral(unreadOnly:pageCursor:kind:)``
    ///   always leaves a v3-synthesized ``NotificationEntry/id`` nil, because v3 has no unified
    ///   notification id — each of its three sources (`getReplies`/`getPersonMentions`/
    ///   `getPrivateMessages`) has its own disjoint id space (see ``NotificationEntry/id``'s doc).
    ///   Calling this method on a v3 backend is therefore a no-op that returns without making a
    ///   request; v3 consumers should mark individual items read via the existing per-kind
    ///   wrappers (`markCommentReplyAsRead(commentReplyID:read:)`,
    ///   `markPersonMentionAsRead(personMentionID:read:)`,
    ///   `markPrivateMessageAsRead(privateMessageID:read:)`), using the id from the concrete v3
    ///   response that produced the item, not this neutral method.
    /// - Note: requires authentication.
    func markNotificationAsReadNeutral(id: Int64, read: Bool) async throws {
        switch apiVersion {
        case .v3:
            return
        case .v4:
            try await markNotificationAsReadNeutralV4(id: id, read: read)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "markNotificationAsRead")
        }
    }

    /// Marks every unread notification in the unified inbox as read.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``): v4's `MarkAllNotificationsAsRead`, or v3's existing `markAllAsRead()`
    /// wrapper.
    ///
    /// - Note: v3's `markAllAsRead()` only marks replies and mentions as read — it does not
    ///   affect private messages (see that method's doc). v4's `MarkAllNotificationsAsRead`
    ///   operates over the single unified inbox, which includes private messages. This asymmetry
    ///   is inherent to the two APIs, not something this method can paper over.
    /// - Note: requires authentication.
    func markAllNotificationsAsReadNeutral() async throws {
        switch apiVersion {
        case .v3:
            try await markAllAsRead()
        case .v4:
            try await markAllNotificationsAsReadNeutralV4()
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "markAllNotificationsAsRead")
        }
    }
}

private extension LemmyApi {
    /// v4 path: calls the v4 generated client's `MarkNotificationAsRead` operation with
    /// `notification_id`/`read`, then confirms it returned success. `MarkNotificationAsRead` only
    /// documents the `ok` response, so anything else falls through to `.undocumented`.
    func markNotificationAsReadNeutralV4(id: Int64, read: Bool) async throws {
        let response: LemmyKitV4Generated.Operations.MarkNotificationAsRead.Output
        do {
            response = try await v4Client.MarkNotificationAsRead(body: .json(.init(
                read: read,
                notification_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 path: calls the v4 generated client's `MarkAllNotificationsAsRead` operation, then
    /// confirms it returned success. Like `markNotificationAsReadNeutralV4`, only the `ok`
    /// response is documented.
    func markAllNotificationsAsReadNeutralV4() async throws {
        let response: LemmyKitV4Generated.Operations.MarkAllNotificationsAsRead.Output
        do {
            response = try await v4Client.MarkAllNotificationsAsRead()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
