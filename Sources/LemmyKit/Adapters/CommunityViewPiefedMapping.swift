//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedCommunityView` to the neutral, v4-shaped `CommunityView` -- the "emulate
/// upward" adapter direction, the same pattern as `CommunityViewV3Mapping.swift`.
///
/// PieFed's `PiefedCommunityView` carries `subscribed`/`blocked`/`banned_from_community` as bare
/// fields rather than v4's single `community_actions` object, so this adapter assembles a
/// `CommunityActions` from them directly: `subscribed` maps via
/// `neutralFollowState(fromPiefedSubscribed:)`, and `blocked`/`banned_from_community` become
/// `v3ActionSentinel` when `true` (PieFed has no timestamp for either, only the current boolean).
/// Unlike `PostView`'s adapter, `banned_from_community` here is the *viewer's own* ban from the
/// community (there is no creator in a bare `CommunityView`), so it maps to
/// `CommunityActions.receivedBanAt` rather than being dropped -- same as v3. Unlike
/// `PiefedPostView`/`PiefedCommentView`, this wire shape's `banned_from_community` is observed
/// `nil` on every live PieFed response captured so far (PieFed doesn't send the key at all on
/// `community/list`), so it is coalesced to `false` here. `canMod` has no PieFed signal to derive
/// from and always maps to `false`.
package func neutralCommunityView(fromPiefed view: PiefedCommunityView) -> CommunityView {
    CommunityView(
        community: neutralCommunity(fromPiefed: view.community, counts: view.counts),
        communityActions: CommunityActions(
            followState: neutralFollowState(fromPiefedSubscribed: view.subscribed),
            blockedAt: view.blocked ? v3ActionSentinel : nil,
            receivedBanAt: (view.banned_from_community ?? false) ? v3ActionSentinel : nil
        ),
        canMod: false
    )
}
