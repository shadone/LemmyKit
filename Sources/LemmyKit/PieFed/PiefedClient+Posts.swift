//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Mark read / hide

    /// `POST /api/alpha/post/mark_as_read` -- returns a bare `{success}` rather than a post view.
    func markPostAsRead(postId: Int64, read: Bool) async throws -> PiefedSuccessResponse {
        try await send(
            .post, "/api/alpha/post/mark_as_read",
            body: PiefedMarkPostAsReadRequestBody(post_id: postId, read: read),
            operationID: "markPostAsRead"
        )
    }

    /// `POST /api/alpha/post/hide` -- hide/unhide a post from feeds. PieFed-only; no Lemmy v3
    /// equivalent. Note the wire field is `hidden`, encoded from the `hide` parameter.
    func hidePost(postId: Int64, hide: Bool) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/hide",
            body: PiefedHidePostRequestBody(post_id: postId, hidden: hide),
            operationID: "hidePost"
        )
    }

    // MARK: - Post create / edit / delete

    /// `POST /api/alpha/post`. The author's own post is auto-upvoted server-side on creation.
    ///
    /// - Parameters:
    ///   - communityId: the community to post into.
    ///   - title: the post title.
    ///   - body: the post markdown body, or nil for a link/no-body post.
    ///   - url: the post's link url, or nil for a text post.
    ///   - nsfw: whether the post is marked NSFW, or nil for the server default (`false`).
    ///   - languageId: the post's language id, or nil for the server default.
    func createPost(
        communityId: Int64,
        title: String,
        body: String? = nil,
        url: String? = nil,
        nsfw: Bool? = nil,
        languageId: Int64? = nil
    ) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post",
            body: PiefedCreatePostRequestBody(
                community_id: communityId, title: title, body: body, url: url, nsfw: nsfw, language_id: languageId
            ),
            operationID: "createPost"
        )
    }

    /// `PUT /api/alpha/post` -- edit a post. Only `postId` is required on the wire; every other
    /// parameter left nil is omitted from the request (the server keeps the existing value).
    func editPost(
        postId: Int64,
        title: String? = nil,
        body: String? = nil,
        url: String? = nil,
        nsfw: Bool? = nil
    ) async throws -> PiefedPostResponse {
        try await send(
            .put, "/api/alpha/post",
            body: PiefedEditPostRequestBody(post_id: postId, title: title, body: body, url: url, nsfw: nsfw),
            operationID: "editPost"
        )
    }

    /// `POST /api/alpha/post/delete` -- soft-deletes (tombstones) a post.
    func deletePost(postId: Int64, deleted: Bool) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/delete",
            body: PiefedDeletePostRequestBody(post_id: postId, deleted: deleted),
            operationID: "deletePost"
        )
    }
}
