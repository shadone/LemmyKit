//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps one item of PieFed's `getReplies`/`getMentions` response to a full neutral
/// `NotificationView` -- the same rebuild-a-view-then-delegate pattern as
/// `CommentReplyNotificationV3Mapping.swift`/`PersonMentionNotificationV3Mapping.swift`.
///
/// `PiefedReplyItem` carries the exact same comment/creator/post/community/counts field set as
/// `PiefedCommentView`, plus its own `comment_reply` (and an unused `recipient` -- the recipient is
/// always the signed-in account, not part of the neutral `CommentView`). Rather than reimplementing
/// comment/person/post/community mapping by hand, this rebuilds a `PiefedCommentView` from the
/// shared fields and hands it to the existing `neutralCommentView(fromPiefed:)`.
///
/// Unlike v3 (whose `CommentReplyView`/`PersonMentionView` are two distinct wire shapes needing two
/// distinct mapping functions), PieFed's `/user/replies` and `/user/mentions` share the *identical*
/// `PiefedReplyItem` shape under the same `replies` wrapper key -- so one function serves both, and
/// the caller (the `listNotifications` endpoint) passes whichever `kind` matches the endpoint it
/// called.
///
/// `PiefedReplyItem` has no equivalent of `PiefedCommentView`'s own `banned_from_community` (the
/// viewer's own ban from the community) -- no PieFed source, defaults to `false`, the same
/// "no signal -> false" convention the other PieFed view adapters use.
///
/// - Parameters:
///   - item: the reply/mention item to map.
///   - kind: `.reply` when called from `getReplies`, `.mention` when called from `getMentions` --
///     `PiefedReplyItem` itself carries no signal that distinguishes the two, since PieFed reuses
///     the identical shape for both endpoints.
/// - Returns: the neutral `NotificationView`, wrapping a `.comment` payload.
package func neutralNotificationView(fromPiefedReply item: PiefedReplyItem, kind: NotificationKind) -> NotificationView {
    let commentView = PiefedCommentView(
        comment: item.comment,
        creator: item.creator,
        post: item.post,
        community: item.community,
        counts: item.counts,
        banned_from_community: false,
        subscribed: item.subscribed ?? "NotSubscribed",
        saved: item.saved ?? false,
        creator_blocked: item.creator_blocked,
        my_vote: item.my_vote ?? 0,
        activity_alert: item.activity_alert,
        creator_banned_from_community: item.creator_banned_from_community ?? false,
        creator_is_moderator: item.creator_is_moderator ?? false,
        creator_is_admin: item.creator_is_admin ?? false,
        can_auth_user_moderate: nil
    )

    return NotificationView(
        notification: NotificationEntry(
            // Unlike v3's three-way fan-out (whose `CommentReplyNotificationV3Mapping.swift`/
            // `PersonMentionNotificationV3Mapping.swift` always leave `id` nil, since v3's
            // disjoint per-endpoint id spaces have no cross-kind identity -- see
            // `NotificationEntry.id`'s doc), PieFed's `comment_reply.id` genuinely IS a stable
            // per-notification mark-read handle (see `PiefedCommentReply`'s doc), shared by both
            // `/user/replies` and `/user/mentions` -- so this feeds it directly rather than
            // leaving it nil.
            id: item.comment_reply.id,
            kind: kind,
            isRead: item.comment_reply.read,
            publishedAt: piefedDate(item.comment_reply.published)
        ),
        data: .comment(neutralCommentView(fromPiefed: commentView))
    )
}
