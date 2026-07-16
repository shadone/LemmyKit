//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Request body structs for PieFed's `/api/alpha` write/auth surface (Phase 2), plus the two
// response-envelope wrappers Task 1 didn't need but the write surface does
// (`PiefedCommentReplyResponse`, `PiefedPrivateMessageResponse`). Like the other hand-written
// `Piefed*` models, these mirror PieFed's raw snake_case wire keys exactly -- the property name
// IS the JSON key -- so `PiefedClient.send(_:_:body:operationID:)`'s plain `JSONEncoder` produces
// the exact shape the probe captured with no `CodingKeys` translation layer. Every struct relies
// on the compiler-synthesized `Encodable` conformance, which encodes `Optional` properties via
// `encodeIfPresent` -- a `nil` parameter is omitted from the JSON entirely (matching "server picks
// its own default" semantics), never sent as a JSON `null`. Shapes are pinned to
// `piefed-alpha-spec.json`'s request schemas and the Phase-2 API probe; see `PiefedClient.swift`
// for the routes that send these.

/// `POST /api/alpha/user/login` request body.
struct PiefedLoginRequestBody: Encodable, Sendable {
    let username: String
    let password: String
}

/// `POST /api/alpha/post/like` request body (`LikePostRequest`).
struct PiefedLikePostRequestBody: Encodable, Sendable {
    let post_id: Int64
    let score: Int
}

/// `POST /api/alpha/comment/like` request body (`LikeCommentRequest`).
struct PiefedLikeCommentRequestBody: Encodable, Sendable {
    let comment_id: Int64
    let score: Int
}

/// `PUT /api/alpha/post/save` request body (`SavePostRequest`).
struct PiefedSavePostRequestBody: Encodable, Sendable {
    let post_id: Int64
    let save: Bool
}

/// `PUT /api/alpha/comment/save` request body (`SaveCommentRequest`).
struct PiefedSaveCommentRequestBody: Encodable, Sendable {
    let comment_id: Int64
    let save: Bool
}

/// `POST /api/alpha/community/follow` request body (`FollowCommunityRequest`) -- this is the
/// membership follow/unfollow, not PieFed's separate `PUT /community/subscribe` activity-alert
/// toggle (no Lemmy v3 equivalent; out of scope here).
struct PiefedFollowCommunityRequestBody: Encodable, Sendable {
    let community_id: Int64
    let follow: Bool
}

/// `POST /api/alpha/post/mark_as_read` request body (`MarkPostAsReadRequest`). PieFed also accepts
/// a `post_ids` array for bulk marking; only the single-post `post_id` form is needed here.
struct PiefedMarkPostAsReadRequestBody: Encodable, Sendable {
    let post_id: Int64
    let read: Bool
}

/// `POST /api/alpha/post/hide` request body (`HidePostRequest`). The wire field is **`hidden`**,
/// not `hide` -- confirmed against `piefed-alpha-spec.json` (the spec's own `hidePost`/`unhidePost`
/// route isn't in the live probe, so this shape is spec-sourced per the task brief).
struct PiefedHidePostRequestBody: Encodable, Sendable {
    let post_id: Int64
    let hidden: Bool
}

/// `POST /api/alpha/comment` request body (`CreateCommentRequest`). `parent_id`/`language_id` are
/// nil for a top-level, default-language comment.
struct PiefedCreateCommentRequestBody: Encodable, Sendable {
    let body: String
    let post_id: Int64
    let parent_id: Int64?
    let language_id: Int64?
}

/// `PUT /api/alpha/comment` request body (`EditCommentRequest`). PieFed also accepts a
/// `distinguished` flag (mod-only "distinguish as mod reply"); not exposed here, no Phase-2 caller
/// needs it yet.
struct PiefedEditCommentRequestBody: Encodable, Sendable {
    let body: String
    let comment_id: Int64
    let language_id: Int64?
}

/// `POST /api/alpha/comment/delete` request body (`DeleteCommentRequest`). PieFed soft-deletes
/// (tombstones) rather than purging.
struct PiefedDeleteCommentRequestBody: Encodable, Sendable {
    let comment_id: Int64
    let deleted: Bool
}

/// `POST /api/alpha/post` request body (`CreatePostRequest`). PieFed accepts several
/// PieFed-specific extensions (`alt_text`, `ai_generated`, `event`, `poll`) not exposed here -- no
/// Phase-2 caller needs them yet.
struct PiefedCreatePostRequestBody: Encodable, Sendable {
    let community_id: Int64
    let title: String
    let body: String?
    let url: String?
    let nsfw: Bool?
    let language_id: Int64?
}

/// `PUT /api/alpha/post` request body (`EditPostRequest`). Only `post_id` is required on the wire;
/// every other field left `nil` here is simply omitted (not the spec's "pass `null` to clear"
/// sentinel some string fields support -- no Phase-2 caller needs clearing yet).
struct PiefedEditPostRequestBody: Encodable, Sendable {
    let post_id: Int64
    let title: String?
    let body: String?
    let url: String?
    let nsfw: Bool?
}

/// `POST /api/alpha/post/delete` request body (`DeletePostRequest`).
struct PiefedDeletePostRequestBody: Encodable, Sendable {
    let post_id: Int64
    let deleted: Bool
}

/// `POST /api/alpha/comment/mark_as_read` request body (`MarkCommentAsReadRequest`) -- marks a
/// single Lemmy-compat reply-inbox notification read/unread, addressed by the notification's own
/// id (`PiefedCommentReply.id`), not the comment's id.
struct PiefedMarkCommentReplyAsReadRequestBody: Encodable, Sendable {
    let comment_reply_id: Int64
    let read: Bool
}

/// The empty body PieFed's no-payload write routes still need a JSON `Content-Type` request for
/// (e.g. `POST /api/alpha/user/mark_all_as_read`, which the probe confirmed takes no body).
/// Encodes to `{}`.
struct PiefedEmptyRequestBody: Encodable, Sendable { }

/// `POST /api/alpha/private_message` request body (`CreatePrivateMessageRequest`).
struct PiefedCreatePrivateMessageRequestBody: Encodable, Sendable {
    let content: String
    let recipient_id: Int64
}

/// `POST /api/alpha/private_message/mark_as_read` request body
/// (`MarkPrivateMessageAsReadRequest`).
struct PiefedMarkPrivateMessageAsReadRequestBody: Encodable, Sendable {
    let private_message_id: Int64
    let read: Bool
}

// MARK: - Response wrappers not produced by Task 1

/// `POST /api/alpha/comment/mark_as_read` response (`GetCommentReplyResponse`) -- wraps the same
/// per-viewer notification shape Task 1 already decodes as `PiefedReplyItem`
/// (`CommentReplyView`), just under this route's own top-level key.
public struct PiefedCommentReplyResponse: Codable, Sendable {
    public let comment_reply_view: PiefedReplyItem
}

/// The response wrapper PieFed's private-message write routes share (`PrivateMessageResponse`):
/// `POST /api/alpha/private_message` (create) and `POST /api/alpha/private_message/mark_as_read`.
public struct PiefedPrivateMessageResponse: Codable, Sendable {
    public let private_message_view: PiefedPrivateMessageView
}
