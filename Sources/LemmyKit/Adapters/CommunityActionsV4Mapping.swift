//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps v4's `community_actions` object to the neutral `CommunityActions`, field-by-field.
/// Shared by the v4 `PostView` and `CommentView` adapters -- both views carry an optional
/// `community_actions` of this exact generated type.
///
/// `notifications` (a per-community notification mode) has no neutral counterpart yet and is
/// dropped.
func neutralCommunityActions(
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
