//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Inbox wire models for PieFed's `/api/alpha` Lemmy-compat notification surface: unread counts, the
// reply/mention inbox item + wrapper, and private messages. Like the other PieFed models these
// mirror PieFed's raw snake_case keys and defer renames to the adapter layer; optionality follows
// the Phase-1 alpha-drift rule. The reply/PM inbox is empty on the validation instance, so
// `PiefedReplyItem` and `PiefedPrivateMessageView` are additionally exercised by synthetic
// spec-shaped fixtures (see `PiefedAuthDecodingTests`). Captured/synthesized 2026-07-15.

/// `GET /api/alpha/user/unread_count` -- the Lemmy-compat inbox counters. Every field is required:
/// the unread-counts adapter reads all four (folding `other` into the neutral total).
public struct PiefedUnreadCountResponse: Codable, Sendable {
    /// Unread post/comment mentions.
    public let mentions: Int
    /// Unread replies to the account's posts/comments.
    public let replies: Int
    /// Unread private messages.
    public let private_messages: Int
    /// Any other unread notification (reports, activity alerts, ...).
    public let other: Int
}

/// A single private message, as embedded in `PiefedPrivateMessageView.private_message`. PieFed's DM
/// body field is **`content`** (matching Lemmy; unlike a comment's `body`).
public struct PiefedPrivateMessage: Codable, Sendable {
    public let id: Int64
    public let creator_id: Int64
    public let recipient_id: Int64
    public let content: String
    /// The recipient's read flag; feeds `PrivateMessageListItem.isRead`.
    public let read: Bool
    public let published: String
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let deleted: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `deleted`.
    public let ap_id: String?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `deleted`.
    public let local: Bool?
}

/// A private message paired with its participants, as returned in
/// `PiefedPrivateMessageListResponse.private_messages` (and by the `private_message` create/edit
/// routes). PieFed adds a `conversation_id` grouping absent from Lemmy v3.
public struct PiefedPrivateMessageView: Codable, Sendable {
    public let private_message: PiefedPrivateMessage
    public let creator: PiefedPerson
    public let recipient: PiefedPerson
    /// The conversation grouping id (PieFed extension). Not read by any neutral adapter -- kept
    /// `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let conversation_id: Int64?
}

/// `GET /api/alpha/private_message/list` -- the account's private-message inbox (empty on the
/// validation instance; the wrapper key is what this pins).
public struct PiefedPrivateMessageListResponse: Codable, Sendable {
    public let private_messages: [PiefedPrivateMessageView]
}

/// The reply-notification pointer embedded in `PiefedReplyItem.comment_reply` -- Lemmy's
/// `CommentReply`. Its `id` is the notification's mark-read handle; `read` is its read state.
public struct PiefedCommentReply: Codable, Sendable {
    public let id: Int64
    public let read: Bool
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let comment_id: Int64?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `comment_id`.
    public let published: String?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `comment_id`.
    public let recipient_id: Int64?
}

/// A single reply/mention inbox item, as returned in `PiefedRepliesResponse.replies` by
/// `GET /api/alpha/user/replies` and `GET /api/alpha/user/mentions`. PieFed's shape is Lemmy's
/// `CommentReplyView`: the notification carries a full embedded comment + its post/community/creator
/// context, so the notification adapter can build a neutral `CommentView` from it.
///
/// The core sub-objects the notification adapter reads (`comment`, `comment_reply`, `community`,
/// `counts`, `creator`, `post`) are required; the per-viewer interaction fields and moderation flags
/// are `Optional` (the adapter defaults them when building the `CommentView`).
public struct PiefedReplyItem: Codable, Sendable {
    public let comment: PiefedComment
    public let comment_reply: PiefedCommentReply
    public let community: PiefedCommunity
    public let counts: PiefedCommentCounts
    public let creator: PiefedPerson
    public let post: PiefedPost
    /// The notification recipient (the requesting account). Not read by any neutral adapter -- kept
    /// `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let recipient: PiefedPerson?
    /// The viewer's vote on the comment (`1`/`0`/`-1`). Kept `Optional`; the adapter defaults it.
    public let my_vote: Int?
    /// Whether the viewer saved the comment. Kept `Optional`; the adapter defaults it.
    public let saved: Bool?
    /// `"NotSubscribed"` | `"Subscribed"` | `"Pending"`. Kept `Optional`; the adapter defaults it.
    public let subscribed: String?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let activity_alert: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let creator_banned_from_community: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let creator_blocked: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let creator_is_admin: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let creator_is_moderator: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `recipient`.
    public let distinguished: Bool?
}

/// `GET /api/alpha/user/replies` and `GET /api/alpha/user/mentions` -- the Lemmy-compat reply/mention
/// inbox. Both routes share the `replies` wrapper key; `next_page` is a nullable string cursor.
public struct PiefedRepliesResponse: Codable, Sendable {
    public let replies: [PiefedReplyItem]
    /// The next-page cursor, or nil on the last page.
    public let next_page: String?
}
