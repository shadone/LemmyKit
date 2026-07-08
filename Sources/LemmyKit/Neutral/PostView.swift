//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A post as seen by a particular viewer: the bare `Post` composed with its creator, community,
/// creator-context flags, and the optional per-viewer action structs, decoupled from the
/// generated OpenAPI schema.
///
/// This mirrors v4's `PostView`. The creator-context flags (`creatorBannedFromCommunity`,
/// `creatorIsModerator`, `creatorIsAdmin`, `creatorBanned`, `canMod`) are read directly off v4's
/// `PostView`, since v4 keeps them there rather than flattening them onto `Person`/`Community`. A
/// V3 backend adapter derives them from the equivalent v3 `PostView` fields (`creator_banned_from_
/// community`, `creator_is_moderator`, `creator_is_admin`, `creator_blocked`/`banned`, `can_mod`).
///
/// The per-viewer actions (`postActions`/`communityActions`/`personActions`) are all optional and
/// default to `nil`, which is the correct shape for a signed-out viewer or any post the viewer has
/// no relationship with. Callers should never read the actions' raw timestamps directly — use the
/// derived properties below, which resolve the nil-defaulting and v3/v4 backend differences in one
/// place.
public struct PostView: Sendable, Equatable {
    /// The post itself.
    public var post: Post

    /// The post's creator.
    public var creator: Person

    /// The community the post was made in.
    public var community: Community

    /// Whether the creator is banned from `community` specifically (as opposed to banned
    /// instance-wide, see `creatorBanned`). Defaults to `false`.
    public var creatorBannedFromCommunity: Bool

    /// Whether the creator moderates `community`. Defaults to `false`.
    public var creatorIsModerator: Bool

    /// Whether the creator is an administrator of the instance the post is being viewed from.
    /// Defaults to `false`.
    public var creatorIsAdmin: Bool

    /// Whether the creator is banned instance-wide (as opposed to only from `community`, see
    /// `creatorBannedFromCommunity`). Defaults to `false`.
    public var creatorBanned: Bool

    /// Whether the viewer can moderate this post (a moderator of `community`, or an admin).
    /// Defaults to `false`.
    public var canMod: Bool

    /// The viewer's per-viewer relationship to the post (read/hidden/saved/vote/comment cursor),
    /// or `nil` for a signed-out viewer or a post never interacted with.
    public var postActions: PostActions?

    /// The viewer's per-viewer relationship to `community` (follow/block/moderator standing), or
    /// `nil` for a signed-out viewer or a community never interacted with.
    public var communityActions: CommunityActions?

    /// The viewer's per-viewer relationship to `creator` (block state), or `nil` for a signed-out
    /// viewer or a person never interacted with.
    public var personActions: PersonActions?

    public init(
        post: Post,
        creator: Person,
        community: Community,
        creatorBannedFromCommunity: Bool = false,
        creatorIsModerator: Bool = false,
        creatorIsAdmin: Bool = false,
        creatorBanned: Bool = false,
        canMod: Bool = false,
        postActions: PostActions? = nil,
        communityActions: CommunityActions? = nil,
        personActions: PersonActions? = nil
    ) {
        self.post = post
        self.creator = creator
        self.community = community
        self.creatorBannedFromCommunity = creatorBannedFromCommunity
        self.creatorIsModerator = creatorIsModerator
        self.creatorIsAdmin = creatorIsAdmin
        self.creatorBanned = creatorBanned
        self.canMod = canMod
        self.postActions = postActions
        self.communityActions = communityActions
        self.personActions = personActions
    }

    /// Whether the viewer has saved the post. `false` when `postActions` is `nil` (a signed-out
    /// viewer, or a post never saved).
    public var isSaved: Bool { postActions?.isSaved ?? false }

    /// Whether the viewer has read the post. `false` when `postActions` is `nil` (a signed-out
    /// viewer, or a post never read).
    public var isRead: Bool { postActions?.isRead ?? false }

    /// Whether the viewer has hidden the post from their feeds. `false` when `postActions` is
    /// `nil` (a signed-out viewer, or a post never hidden).
    public var isHidden: Bool { postActions?.isHidden ?? false }

    /// The viewer's vote on the post. `.none` when `postActions` is `nil` (a signed-out viewer,
    /// or a post never voted on).
    public var myVote: VoteDirection { postActions?.vote ?? .none }

    /// The viewer's follow state for `community`. `.notFollowing` when `communityActions` is
    /// `nil`, matching v4's "absence means not following" semantics (see
    /// `CommunityActions.resolvedFollowState`).
    public var followState: FollowState { communityActions?.resolvedFollowState ?? .notFollowing }

    /// Whether the viewer has blocked `creator`. `false` when `personActions` is `nil` (a
    /// signed-out viewer, or a creator never blocked).
    public var isCreatorBlocked: Bool { personActions?.isBlocked ?? false }

    /// The number of comments on the post the viewer has not yet seen, derived from the post's
    /// total comment count minus how many the viewer had seen as of their last visit
    /// (`postActions.readCommentsAmount`). Floored at `0` — never negative, even if the viewer's
    /// recorded count is stale and exceeds the post's current comment count (e.g. comments were
    /// since removed). `postActions == nil` (or `readCommentsAmount == nil`) is treated as "seen
    /// none yet," so the full comment count is unread.
    public var unreadCommentCount: Int64 {
        max(0, post.comments - (postActions?.readCommentsAmount ?? 0))
    }
}
