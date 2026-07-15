//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Comment create / edit / delete

    /// `POST /api/alpha/comment`. The comment body field is **`body`** (Lemmy v3: `content`). The
    /// author's own comment is auto-upvoted server-side on creation.
    ///
    /// - Parameters:
    ///   - body: the comment markdown body.
    ///   - postId: the post being commented on.
    ///   - parentId: the parent comment id for a reply, or nil for a top-level comment.
    ///   - languageId: the comment's language id, or nil for the server default.
    func createComment(
        body: String,
        postId: Int64,
        parentId: Int64? = nil,
        languageId: Int64? = nil
    ) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment",
            body: PiefedCreateCommentRequestBody(
                body: body, post_id: postId, parent_id: parentId, language_id: languageId
            ),
            operationID: "createComment"
        )
    }

    /// `PUT /api/alpha/comment` -- edit a comment's body/language.
    func editComment(
        commentId: Int64,
        body: String,
        languageId: Int64? = nil
    ) async throws -> PiefedCommentResponse {
        try await send(
            .put, "/api/alpha/comment",
            body: PiefedEditCommentRequestBody(body: body, comment_id: commentId, language_id: languageId),
            operationID: "editComment"
        )
    }

    /// `POST /api/alpha/comment/delete` -- soft-deletes (tombstones) a comment; PieFed's
    /// `/api/alpha` write surface has no hard-delete.
    func deleteComment(commentId: Int64, deleted: Bool) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment/delete",
            body: PiefedDeleteCommentRequestBody(comment_id: commentId, deleted: deleted),
            operationID: "deleteComment"
        )
    }

    /// `POST /api/alpha/comment/mark_as_read` -- marks a single reply-inbox notification
    /// read/unread, addressed by the notification's own id (not the comment's id).
    func markCommentReplyAsRead(commentReplyId: Int64, read: Bool) async throws -> PiefedCommentReplyResponse {
        try await send(
            .post, "/api/alpha/comment/mark_as_read",
            body: PiefedMarkCommentReplyAsReadRequestBody(comment_reply_id: commentReplyId, read: read),
            operationID: "markCommentReplyAsRead"
        )
    }
}
