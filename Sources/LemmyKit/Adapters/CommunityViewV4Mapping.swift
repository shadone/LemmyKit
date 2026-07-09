//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.CommunityView` to the neutral `CommunityView` -- the
/// near-direct adapter direction (see `PostViewV4Mapping.swift`'s header for the general shape
/// of this direction). `community_actions` carries the exact same generated type as the v4
/// `PostView`/`CommentView` adapters, so it's mapped via the shared
/// `neutralCommunityActions(fromV4:)` and carried through as `nil` when absent (a signed-out
/// viewer, or a community never interacted with).
///
/// v4's `tags: CommunityTagsView` field has no neutral counterpart -- community tagging isn't
/// part of the neutral `CommunityView` in this phase -- and is dropped.
package func neutralCommunityView(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.CommunityView
) -> CommunityView {
    CommunityView(
        community: neutralCommunity(fromV4: v4.community),
        communityActions: v4.community_actions.map(neutralCommunityActions(fromV4:)),
        canMod: v4.can_mod
    )
}
