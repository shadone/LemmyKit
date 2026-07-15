//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Inbox (Lemmy-compat replies/mentions)

    /// `GET /api/alpha/user/replies` -- the Lemmy-compat comment-reply inbox.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread replies, or nil for the server default (`true`).
    ///   - page: the 1-based page number, or nil for the first page.
    func getReplies(unreadOnly: Bool? = nil, page: Int? = nil) async throws -> PiefedRepliesResponse {
        try await get(
            "/api/alpha/user/replies",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getReplies"
        )
    }

    /// `GET /api/alpha/user/mentions` -- the Lemmy-compat mention inbox. Shares the `replies`
    /// wrapper key with ``getReplies(unreadOnly:page:)``.
    func getMentions(unreadOnly: Bool? = nil, page: Int? = nil) async throws -> PiefedRepliesResponse {
        try await get(
            "/api/alpha/user/mentions",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getMentions"
        )
    }

    /// `POST /api/alpha/user/mark_all_as_read` -- marks the whole Lemmy-compat reply inbox read.
    /// Confirmed live to take no request body.
    func markAllAsRead() async throws -> PiefedRepliesResponse {
        try await send(
            .post, "/api/alpha/user/mark_all_as_read",
            body: PiefedEmptyRequestBody(),
            operationID: "markAllAsRead"
        )
    }
}
