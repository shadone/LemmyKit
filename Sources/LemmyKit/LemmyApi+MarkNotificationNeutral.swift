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
            try await markNotificationAsReadNeutralPiefed(id: id, read: read)
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
            try await markAllNotificationsAsReadNeutralPiefed()
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

    /// PieFed path: calls `PiefedClient.markCommentReplyAsRead(commentReplyId:read:)` -- `POST
    /// /api/alpha/comment/mark_as_read`, `{comment_reply_id, read}` -- with `id` directly, and
    /// discards the response (mirroring `markNotificationAsReadNeutralV4`, which likewise discards
    /// its `ok` response).
    ///
    /// ## Resolving the mention mark-read ambiguity
    ///
    /// The neutral `id` this method receives carries no `kind` (see
    /// ``markNotificationAsReadNeutral(id:read:)``'s doc), so at this call site there is no way to
    /// tell a reply-sourced id from a mention-sourced one. On PieFed this turns out not to matter:
    /// the vendored alpha spec resolves both `UserRepliesResponse` (`GET /api/alpha/user/replies`)
    /// and `UserMentionsResponse` (`GET /api/alpha/user/mentions`) to the exact same
    /// `CommentReplyView` schema -- PieFed's Lemmy-compat "mention" notification genuinely IS a
    /// comment-reply notification under the hood, addressed by the same `comment_reply.id` space
    /// (see `PiefedReplyItem`/`PiefedCommentReply`'s docs and
    /// `neutralNotificationView(fromPiefedReply:kind:)`, which already established this when it
    /// fed `comment_reply.id` onto the neutral `NotificationEntry.id` for BOTH kinds, unlike v3's
    /// fan-out, which always leaves `id` nil precisely because its three sources have disjoint id
    /// spaces). So a single route -- this one -- correctly marks read/unread ids sourced from
    /// either `listNotificationsNeutral(kind: .reply)` or `listNotificationsNeutral(kind: .mention)`,
    /// with no ambiguity and no need to special-case by kind.
    ///
    /// The alternative surface, `PUT /api/alpha/user/notification_state`
    /// (`{notif_id, read_state}`), addresses PieFed's separate *native* unified-notification id
    /// space (`notif_id`, from `GET /api/alpha/user/notifications`) -- a surface this dialect does
    /// not otherwise speak (`listNotificationsNeutralPiefed` only ever calls the Lemmy-compat
    /// `getReplies`/`getMentions`), so it would receive an id from a completely different id space
    /// and was deliberately not used here.
    func markNotificationAsReadNeutralPiefed(id: Int64, read: Bool) async throws {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "markNotificationAsRead") }
        _ = try await piefedClient.markCommentReplyAsRead(commentReplyId: id, read: read)
    }

    /// PieFed path: calls `PiefedClient.markAllAsRead()` (`POST /api/alpha/user/mark_all_as_read`),
    /// discarding its response body -- the same "Lemmy-compat inbox only, not private messages"
    /// asymmetry v3's `markAllAsRead()` wrapper has against v4's unified inbox (see this method's
    /// public doc) applies here too: PieFed's route is documented "mark all notifications and
    /// messages as read" at the schema level, but this dialect has not independently verified
    /// live whether it actually reaches private messages (Task 9's live validation should confirm
    /// either way) -- ``markAllNotificationsAsReadNeutral()``'s doc already states the v3/v4
    /// asymmetry as the general expectation for a non-v4 backend.
    func markAllNotificationsAsReadNeutralPiefed() async throws {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "markAllNotificationsAsRead") }
        _ = try await piefedClient.markAllAsRead()
    }
}
