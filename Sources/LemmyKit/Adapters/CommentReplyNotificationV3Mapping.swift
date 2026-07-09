//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps one item of v3's `getReplies` response to a full neutral `NotificationView` — one leg of
/// the three-way fan-out ``LemmyApi/listNotificationsNeutral(unreadOnly:pageCursor:)``'s v3 path
/// merges (see that method's doc).
///
/// `Components.Schemas.CommentReplyView` carries the exact same comment/creator/post/community/
/// counts/... field set as `Components.Schemas.CommentView`, plus its own `comment_reply` (and a
/// `recipient`, unused here — the recipient is always the signed-in account, not part of the
/// neutral `CommentView`). Rather than reimplementing comment/person/post/community mapping by
/// hand, this rebuilds a `Components.Schemas.CommentView` from the shared fields and hands it to
/// the existing `neutralCommentView(fromV3:)`.
package func neutralNotificationView(fromV3Reply reply: Components.Schemas.CommentReplyView) -> NotificationView {
    let commentView = Components.Schemas.CommentView(
        comment: reply.comment,
        creator: reply.creator,
        post: reply.post,
        community: reply.community,
        counts: reply.counts,
        creator_banned_from_community: reply.creator_banned_from_community,
        banned_from_community: reply.banned_from_community,
        creator_is_moderator: reply.creator_is_moderator,
        creator_is_admin: reply.creator_is_admin,
        subscribed: reply.subscribed,
        saved: reply.saved,
        creator_blocked: reply.creator_blocked,
        my_vote: reply.my_vote
    )

    return NotificationView(
        notification: Notification(
            id: nil,
            kind: .reply,
            isRead: reply.comment_reply.read,
            publishedAt: reply.comment_reply.published
        ),
        data: .comment(neutralCommentView(fromV3: commentView))
    )
}
