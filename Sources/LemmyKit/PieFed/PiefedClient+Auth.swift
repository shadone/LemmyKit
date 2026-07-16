//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Auth + identity

    /// `POST /api/alpha/user/login`. PieFed logs in by **username** (not email, unlike Lemmy
    /// v3's `username_or_email`), with no 2FA field.
    ///
    /// - Parameters:
    ///   - username: the account's username.
    ///   - password: the account's password.
    /// - Returns: the bearer JWT to send as `Authorization: Bearer <jwt>` on every subsequent
    ///   authed request.
    func login(username: String, password: String) async throws -> PiefedLoginResponse {
        try await send(
            .post, "/api/alpha/user/login",
            body: PiefedLoginRequestBody(username: username, password: password),
            operationID: "login"
        )
    }

    /// `GET /api/alpha/user/me` -- the dedicated my-user route. Note its `follows` list is
    /// observed empty even while subscribed to communities; prefer ``getSiteAuthed()``'s
    /// `my_user` embed when the populated follow list is needed.
    func userMe() async throws -> PiefedUserMeResponse {
        try await get("/api/alpha/user/me", query: [], operationID: "userMe")
    }

    /// `GET /api/alpha/site` sent with the client's bearer token, which adds the authenticated
    /// account's `my_user` embed (see ``PiefedGetSiteResponse/my_user``).
    ///
    /// Identical to ``getSite()`` -- PieFed rides the authed identity embed on the same route
    /// rather than a dedicated endpoint -- kept as a distinctly-named call site for callers that
    /// specifically want the authed embed (mirrors `getSiteAndMyUserNeutral`'s single-fetch use).
    func getSiteAuthed() async throws -> PiefedGetSiteResponse {
        try await getSite()
    }

    /// `GET /api/alpha/user/unread_count` -- the Lemmy-compat inbox counters
    /// (mentions/replies/private messages/other).
    func unreadCount() async throws -> PiefedUnreadCountResponse {
        try await get("/api/alpha/user/unread_count", query: [], operationID: "unreadCount")
    }

    // MARK: - Person details

    /// `GET /api/alpha/user` -- a person's profile plus (when `includeContent` is true) a page of
    /// their posts and comments.
    ///
    /// - Parameters:
    ///   - personId: the person id to fetch.
    ///   - includeContent: true to include the person's posts/comments, or nil for the server
    ///     default (`false`).
    ///   - page: the 1-based page number for the included posts/comments, or nil for the server
    ///     default (1). Meaningless when `includeContent` is not true.
    ///   - limit: the page size for the included posts/comments, or nil for the server default
    ///     (20). Meaningless when `includeContent` is not true.
    func getPersonDetails(
        personId: Int64,
        includeContent: Bool? = nil,
        page: Int? = nil,
        limit: Int? = nil
    ) async throws -> PiefedPersonDetailsResponse {
        try await get(
            "/api/alpha/user",
            query: [
                ("person_id", String(personId)),
                ("include_content", includeContent.map(String.init)),
                ("page", page.map(String.init)),
                ("limit", limit.map(String.init)),
            ],
            operationID: "getPersonDetails"
        )
    }
}
