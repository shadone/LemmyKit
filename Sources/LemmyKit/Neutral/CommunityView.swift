//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A community as seen by a particular viewer: the bare `Community` composed with the viewer's
/// optional per-viewer action struct and a moderation flag, decoupled from the generated OpenAPI
/// schema.
///
/// This mirrors v4's `CommunityView` — the same composition pattern as `PostView`/`CommentView`,
/// but smaller: a `CommunityView` has no creator and no post/comment-specific context, just the
/// community itself, the viewer's follow/block/moderator standing, and whether the viewer can
/// moderate it.
///
/// `communityActions` is optional and defaults to `nil`, which is the correct shape for a
/// signed-out viewer or a community the viewer has no relationship with. Callers should never
/// read its raw timestamps directly — use the derived properties below, which resolve the
/// nil-defaulting and v3/v4 backend differences in one place.
public struct CommunityView: Sendable, Equatable {
    /// The community itself.
    public var community: Community

    /// The viewer's per-viewer relationship to `community` (follow/block/moderator standing), or
    /// `nil` for a signed-out viewer or a community never interacted with.
    public var communityActions: CommunityActions?

    /// Whether the viewer can moderate this community (a moderator of it, or an admin). Defaults
    /// to `false`.
    ///
    /// v4 carries this directly on its `CommunityView`. v3 has no equivalent signal to derive it
    /// from — a V3 backend adapter always maps this to `false`.
    public var canMod: Bool

    public init(
        community: Community,
        communityActions: CommunityActions? = nil,
        canMod: Bool = false
    ) {
        self.community = community
        self.communityActions = communityActions
        self.canMod = canMod
    }

    /// The viewer's follow state for `community`. `.notFollowing` when `communityActions` is
    /// `nil`, matching v4's "absence means not following" semantics (see
    /// `CommunityActions.resolvedFollowState`).
    public var followState: FollowState { communityActions?.resolvedFollowState ?? .notFollowing }

    /// Whether the viewer has blocked `community`. `false` when `communityActions` is `nil` (a
    /// signed-out viewer, or a community never blocked).
    public var isBlocked: Bool { communityActions?.isBlocked ?? false }
}
