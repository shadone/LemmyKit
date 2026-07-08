//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.PostView` to the neutral `PostView` -- the near-direct adapter
/// direction (see the Phase 5 design doc's "PostView / CommentView" section). v4's shape already
/// matches the neutral one field-for-field: rename snake_case to camelCase, parse the
/// string-typed timestamps (`v4Date`, see `V4DateParsing.swift`), and carry each optional
/// `post_actions`/`community_actions`/`person_actions` through as `nil` when absent (a
/// signed-out viewer, or no relationship established yet with the post/community/creator).
///
/// v4's `tags: CommunityTagsView` field has no neutral counterpart -- community tagging isn't
/// part of the neutral `PostView` in this phase -- and is dropped.
package func neutralPostView(fromV4 v4: LemmyKitV4Generated.Components.Schemas.PostView) -> PostView {
    PostView(
        post: neutralPost(fromV4: v4.post),
        creator: neutralPerson(fromV4: v4.creator),
        community: neutralCommunity(fromV4: v4.community),
        creatorBannedFromCommunity: v4.creator_banned_from_community,
        creatorIsModerator: v4.creator_is_moderator,
        creatorIsAdmin: v4.creator_is_admin,
        creatorBanned: v4.creator_banned,
        canMod: v4.can_mod,
        postActions: v4.post_actions.map(neutralPostActions(fromV4:)),
        communityActions: v4.community_actions.map(neutralCommunityActions(fromV4:)),
        personActions: v4.person_actions.map(neutralPersonActions(fromV4:))
    )
}

/// Maps v4's `post_actions` object to the neutral `PostActions`, field-by-field.
///
/// `notifications` (a per-post notification mode) has no neutral counterpart yet and is
/// dropped.
private func neutralPostActions(
    fromV4 actions: LemmyKitV4Generated.Components.Schemas.PostActions
) -> PostActions {
    PostActions(
        readAt: v4Date(actions.read_at),
        hiddenAt: v4Date(actions.hidden_at),
        savedAt: v4Date(actions.saved_at),
        votedAt: v4Date(actions.voted_at),
        voteIsUpvote: actions.vote_is_upvote,
        readCommentsAt: v4Date(actions.read_comments_at),
        readCommentsAmount: actions.read_comments_amount
    )
}

/// Maps v4's `community_actions` object to the neutral `CommunityActions`, field-by-field.
///
/// `notifications` (a per-community notification mode) has no neutral counterpart yet and is
/// dropped.
private func neutralCommunityActions(
    fromV4 actions: LemmyKitV4Generated.Components.Schemas.CommunityActions
) -> CommunityActions {
    CommunityActions(
        followState: actions.follow_state.map(neutralFollowState(fromV4:)),
        followedAt: v4Date(actions.followed_at),
        blockedAt: v4Date(actions.blocked_at),
        receivedBanAt: v4Date(actions.received_ban_at),
        banExpiresAt: v4Date(actions.ban_expires_at),
        becameModeratorAt: v4Date(actions.became_moderator_at)
    )
}

/// Maps v4's `person_actions` object to the neutral `PersonActions`, field-by-field.
///
/// v4's vote-tally fields (`upvotes`/`downvotes`, aggregate votes this viewer has cast on the
/// person) have no neutral counterpart -- see `Neutral/PersonActions.swift`'s header (dropped
/// per YAGNI) -- and are dropped here too.
private func neutralPersonActions(
    fromV4 actions: LemmyKitV4Generated.Components.Schemas.PersonActions
) -> PersonActions {
    PersonActions(
        blockedAt: v4Date(actions.blocked_at),
        note: actions.note,
        notedAt: v4Date(actions.noted_at)
    )
}

/// Maps v4's `CommunityFollowerState` 1:1 onto the neutral `FollowState`. The neutral-only
/// `.notFollowing` case is handled by `PostView.followState`'s nil-default (when
/// `communityActions` or its `followState` is absent), not by this function.
private func neutralFollowState(
    fromV4 state: LemmyKitV4Generated.Components.Schemas.CommunityFollowerState
) -> FollowState {
    switch state {
    case .accepted:
        .accepted
    case .pending:
        .pending
    case .approval_required:
        .approvalRequired
    case .denied:
        .denied
    }
}
