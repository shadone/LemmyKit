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

// `neutralCommunityActions(fromV4:)`, `neutralPersonActions(fromV4:)`, and
// `neutralFollowState(fromV4:)` moved to `CommunityActionsV4Mapping.swift`,
// `PersonActionsV4Mapping.swift`, and `FollowStateMapping.swift` respectively -- they are shared
// verbatim with the `CommentView` v4 adapter, which carries the exact same `community_actions`/
// `person_actions` generated types.
