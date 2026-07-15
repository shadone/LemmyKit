//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Private messages

    /// `GET /api/alpha/private_message/list`.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread messages, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page.
    ///   - limit: the page size, or nil for the server default. The vendored alpha spec gives no
    ///     documented default for this route (unlike `getReplies`/`getMentions`, which default to
    ///     10) -- ``LemmyApi/getPrivateMessagesNeutral(unreadOnly:pageCursor:)``'s PieFed path sends
    ///     this explicitly so its `nextPage` synthesis (full-page heuristic, this response carries
    ///     no native cursor) can reliably compare a returned count against a known value.
    func getPrivateMessages(
        unreadOnly: Bool? = nil,
        page: Int? = nil,
        limit: Int? = nil
    ) async throws -> PiefedPrivateMessageListResponse {
        try await get(
            "/api/alpha/private_message/list",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
                ("limit", limit.map(String.init)),
            ],
            operationID: "getPrivateMessages"
        )
    }

    /// `POST /api/alpha/private_message` -- send a direct message. The DM body field is
    /// **`content`** (matching Lemmy v3; unlike a comment's `body`).
    func createPrivateMessage(content: String, recipientId: Int64) async throws -> PiefedPrivateMessageResponse {
        try await send(
            .post, "/api/alpha/private_message",
            body: PiefedCreatePrivateMessageRequestBody(content: content, recipient_id: recipientId),
            operationID: "createPrivateMessage"
        )
    }

    /// `POST /api/alpha/private_message/mark_as_read`.
    func markPrivateMessageAsRead(
        privateMessageId: Int64,
        read: Bool
    ) async throws -> PiefedPrivateMessageResponse {
        try await send(
            .post, "/api/alpha/private_message/mark_as_read",
            body: PiefedMarkPrivateMessageAsReadRequestBody(private_message_id: privateMessageId, read: read),
            operationID: "markPrivateMessageAsRead"
        )
    }
}
