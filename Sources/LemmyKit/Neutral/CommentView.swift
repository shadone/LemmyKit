//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A comment as seen by a particular viewer: the bare `Comment` composed with its creator, post,
/// community, creator-context flags, and the optional per-viewer action structs, decoupled from
/// the generated OpenAPI schema.
///
/// This mirrors v4's `CommentView` — the same composition pattern as `PostView`, with the smaller
/// `CommentActions` (comments have no read/hidden state or comment-thread cursor). The
/// creator-context flags (`creatorBannedFromCommunity`, `creatorIsModerator`, `creatorIsAdmin`,
/// `creatorBanned`, `canMod`) are read directly off v4's `CommentView`; a V3 backend adapter
/// derives them from the equivalent v3 `CommentView` fields.
///
/// The per-viewer actions (`commentActions`/`communityActions`/`personActions`) are all optional
/// and default to `nil`, which is the correct shape for a signed-out viewer or any comment the
/// viewer has no relationship with. Callers should never read the actions' raw timestamps
/// directly — use the derived properties below, which resolve the nil-defaulting and v3/v4
/// backend differences in one place.
public struct CommentView: Sendable, Equatable {
    /// The comment itself.
    public var comment: Comment

    /// The comment's creator.
    public var creator: Person

    /// The post the comment belongs to.
    public var post: Post

    /// The community the post (and so the comment) belongs to.
    public var community: Community

    /// Whether the creator is banned from `community` specifically (as opposed to banned
    /// instance-wide, see `creatorBanned`). Defaults to `false`.
    public var creatorBannedFromCommunity: Bool

    /// Whether the creator moderates `community`. Defaults to `false`.
    public var creatorIsModerator: Bool

    /// Whether the creator is an administrator of the instance the comment is being viewed from.
    /// Defaults to `false`.
    public var creatorIsAdmin: Bool

    /// Whether the creator is banned instance-wide (as opposed to only from `community`, see
    /// `creatorBannedFromCommunity`). Defaults to `false`.
    public var creatorBanned: Bool

    /// Whether the viewer can moderate this comment (a moderator of `community`, or an admin).
    /// Defaults to `false`.
    public var canMod: Bool

    /// The viewer's per-viewer relationship to the comment (saved/vote), or `nil` for a
    /// signed-out viewer or a comment never interacted with.
    public var commentActions: CommentActions?

    /// The viewer's per-viewer relationship to `community` (follow/block/moderator standing), or
    /// `nil` for a signed-out viewer or a community never interacted with.
    public var communityActions: CommunityActions?

    /// The viewer's per-viewer relationship to `creator` (block state), or `nil` for a signed-out
    /// viewer or a person never interacted with.
    public var personActions: PersonActions?

    public init(
        comment: Comment,
        creator: Person,
        post: Post,
        community: Community,
        creatorBannedFromCommunity: Bool = false,
        creatorIsModerator: Bool = false,
        creatorIsAdmin: Bool = false,
        creatorBanned: Bool = false,
        canMod: Bool = false,
        commentActions: CommentActions? = nil,
        communityActions: CommunityActions? = nil,
        personActions: PersonActions? = nil
    ) {
        self.comment = comment
        self.creator = creator
        self.post = post
        self.community = community
        self.creatorBannedFromCommunity = creatorBannedFromCommunity
        self.creatorIsModerator = creatorIsModerator
        self.creatorIsAdmin = creatorIsAdmin
        self.creatorBanned = creatorBanned
        self.canMod = canMod
        self.commentActions = commentActions
        self.communityActions = communityActions
        self.personActions = personActions
    }

    /// Whether the viewer has saved the comment. `false` when `commentActions` is `nil` (a
    /// signed-out viewer, or a comment never saved).
    public var isSaved: Bool { commentActions?.isSaved ?? false }

    /// The viewer's vote on the comment. `.none` when `commentActions` is `nil` (a signed-out
    /// viewer, or a comment never voted on).
    public var myVote: VoteDirection { commentActions?.vote ?? .none }

    /// The viewer's follow state for `community`. `.notFollowing` when `communityActions` is
    /// `nil`, matching v4's "absence means not following" semantics (see
    /// `CommunityActions.resolvedFollowState`).
    public var followState: FollowState { communityActions?.resolvedFollowState ?? .notFollowing }

    /// Whether the viewer has blocked `creator`. `false` when `personActions` is `nil` (a
    /// signed-out viewer, or a creator never blocked).
    public var isCreatorBlocked: Bool { personActions?.isBlocked ?? false }
}
