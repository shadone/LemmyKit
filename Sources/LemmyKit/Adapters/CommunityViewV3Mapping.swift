//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.CommunityView` to the neutral, v4-shaped `CommunityView` -- the
/// "emulate upward" adapter direction (see `PostViewV3Mapping.swift`'s header for the general
/// shape of this direction).
///
/// v3's `CommunityView` carries `subscribed`/`blocked`/`banned_from_community` as bare fields
/// rather than v4's single `community_actions` object, so this adapter assembles a
/// `CommunityActions` from them directly: `subscribed` maps via `neutralFollowState(fromV3:)`,
/// and `blocked`/`banned_from_community` become `v3ActionSentinel` when `true` (v3 has no
/// timestamp for either, only the current boolean -- see `V3ActionSentinel.swift`). Unlike
/// `PostView`'s v3 adapter, `banned_from_community` here is the *viewer's own* ban from the
/// community (there is no creator in a bare `CommunityView`), so it maps to
/// `CommunityActions.receivedBanAt` rather than being dropped. `canMod` has no v3 signal to
/// derive from and always maps to `false`.
package func neutralCommunityView(fromV3 v3: Components.Schemas.CommunityView) -> CommunityView {
    CommunityView(
        community: neutralCommunity(fromV3: v3.community, counts: v3.counts),
        communityActions: CommunityActions(
            followState: neutralFollowState(fromV3: v3.subscribed),
            blockedAt: v3.blocked ? v3ActionSentinel : nil,
            receivedBanAt: v3.banned_from_community ? v3ActionSentinel : nil
        ),
        canMod: false
    )
}
