//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps v3's 3-state `SubscribedType` to the neutral `FollowState`. Shared by the v3 `PostView`
/// and `CommentView` adapters -- both views carry a bare `subscribed: SubscribedType` field.
/// `.approvalRequired`/`.denied` are v4-only -- v3's `Pending` collapses both "awaiting mod
/// approval" and "denied" into the same case, so a v3 backend can never produce them.
func neutralFollowState(fromV3 subscribed: Components.Schemas.SubscribedType) -> FollowState {
    switch subscribed {
    case .Subscribed:
        .accepted
    case .Pending:
        .pending
    case .NotSubscribed:
        .notFollowing
    }
}

/// Maps v4's `CommunityFollowerState` 1:1 onto the neutral `FollowState`. Shared by the v4
/// `PostView` and `CommentView` adapters -- both views carry an optional
/// `community_actions.follow_state` of this type. The neutral-only `.notFollowing` case is
/// handled by the composed view's `followState` nil-default (when `communityActions` or its
/// `followState` is absent), not by this function.
func neutralFollowState(
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
