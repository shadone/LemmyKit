//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps one item of v3's `getPersonMentions` response to a full neutral `NotificationView` — one
/// leg of the three-way fan-out ``LemmyApi/listNotificationsNeutral(unreadOnly:pageCursor:)``'s
/// v3 path merges (see that method's doc).
///
/// `Components.Schemas.PersonMentionView` carries the exact same comment/creator/post/community/
/// counts/... field set as `Components.Schemas.CommentView`, plus its own `person_mention` (and a
/// `recipient`, unused here — the recipient is always the signed-in account, not part of the
/// neutral `CommentView`). Rather than reimplementing comment/person/post/community mapping by
/// hand, this rebuilds a `Components.Schemas.CommentView` from the shared fields and hands it to
/// the existing `neutralCommentView(fromV3:)` — the same pattern as
/// `CommentReplyNotificationV3Mapping.swift`.
package func neutralNotificationView(fromV3Mention mention: Components.Schemas.PersonMentionView) -> NotificationView {
    let commentView = Components.Schemas.CommentView(
        comment: mention.comment,
        creator: mention.creator,
        post: mention.post,
        community: mention.community,
        counts: mention.counts,
        creator_banned_from_community: mention.creator_banned_from_community,
        banned_from_community: mention.banned_from_community,
        creator_is_moderator: mention.creator_is_moderator,
        creator_is_admin: mention.creator_is_admin,
        subscribed: mention.subscribed,
        saved: mention.saved,
        creator_blocked: mention.creator_blocked,
        my_vote: mention.my_vote
    )

    return NotificationView(
        notification: Notification(
            id: nil,
            kind: .mention,
            isRead: mention.person_mention.read,
            publishedAt: mention.person_mention.published
        ),
        data: .comment(neutralCommentView(fromV3: commentView))
    )
}
