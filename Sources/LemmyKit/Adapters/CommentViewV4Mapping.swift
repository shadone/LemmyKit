//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.CommentView` to the neutral `CommentView` -- the near-direct
/// adapter direction (see the Phase 5 design doc's "PostView / CommentView" section). v4's shape
/// already matches the neutral one field-for-field: rename snake_case to camelCase, parse the
/// string-typed timestamps (`v4Date`, see `V4DateParsing.swift`), and carry each optional
/// `comment_actions`/`community_actions`/`person_actions` through as `nil` when absent (a
/// signed-out viewer, or no relationship established yet with the comment/community/creator).
///
/// v4's `tags: CommunityTagsView` field has no neutral counterpart -- community tagging isn't
/// part of the neutral `CommentView` in this phase -- and is dropped, matching
/// `PostViewV4Mapping.swift`.
package func neutralCommentView(fromV4 v4: LemmyKitV4Generated.Components.Schemas.CommentView) -> CommentView {
    CommentView(
        comment: neutralComment(fromV4: v4.comment),
        creator: neutralPerson(fromV4: v4.creator),
        post: neutralPost(fromV4: v4.post),
        community: neutralCommunity(fromV4: v4.community),
        creatorBannedFromCommunity: v4.creator_banned_from_community,
        creatorIsModerator: v4.creator_is_moderator,
        creatorIsAdmin: v4.creator_is_admin,
        creatorBanned: v4.creator_banned,
        canMod: v4.can_mod,
        commentActions: v4.comment_actions.map(neutralCommentActions(fromV4:)),
        communityActions: v4.community_actions.map(neutralCommunityActions(fromV4:)),
        personActions: v4.person_actions.map(neutralPersonActions(fromV4:))
    )
}

/// Maps v4's `comment_actions` object to the neutral `CommentActions`, field-by-field.
private func neutralCommentActions(
    fromV4 actions: LemmyKitV4Generated.Components.Schemas.CommentActions
) -> CommentActions {
    CommentActions(
        savedAt: v4Date(actions.saved_at),
        votedAt: v4Date(actions.voted_at),
        voteIsUpvote: actions.vote_is_upvote
    )
}
