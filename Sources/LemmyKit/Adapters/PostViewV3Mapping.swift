//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.PostView` to the neutral, v4-shaped `PostView` -- the "emulate
/// upward" adapter direction (see the Phase 5 design doc's "PostView / CommentView" section).
///
/// v3 has no per-viewer timestamps, only bare booleans (`saved`, `read`, `hidden`,
/// `creator_blocked`) and a signed vote score (`my_vote`). Every neutral `*At` field below is
/// therefore either `nil` (the corresponding v3 boolean is `false`/absent) or `v3ActionSentinel`
/// (the boolean is `true`, but v3 doesn't tell us when it became true) -- see
/// `V3ActionSentinel.swift`. Callers must read the derived `is*`/`vote`/`resolvedFollowState`
/// properties on the neutral action structs, never the raw dates, which is exactly what makes a
/// v3- and a v4-backed `PostView` read identically at the call site.
package func neutralPostView(fromV3 v3: Components.Schemas.PostView) -> PostView {
    let post = neutralPost(fromV3: v3.post, counts: v3.counts)

    return PostView(
        post: post,
        creator: neutralPerson(fromV3: v3.creator),
        community: neutralCommunity(fromV3: v3.community),
        creatorBannedFromCommunity: v3.creator_banned_from_community,
        creatorIsModerator: v3.creator_is_moderator,
        creatorIsAdmin: v3.creator_is_admin,
        // v3's `banned_from_community` (undocumented in the spec, distinct from
        // `creator_banned_from_community` above) is the instance-wide ban flag that v4 calls
        // `creator_banned`.
        creatorBanned: v3.banned_from_community,
        // v3 has no equivalent of v4's `can_mod` (whether the viewer themself can moderate this
        // post) -- there is no v3 signal to derive it from, so it defaults to `false`.
        canMod: false,
        postActions: neutralPostActions(fromV3: v3, post: post),
        communityActions: CommunityActions(followState: neutralFollowState(fromV3: v3.subscribed)),
        personActions: PersonActions(blockedAt: v3.creator_blocked ? v3ActionSentinel : nil)
    )
}

/// Builds the neutral `PostActions` for a v3 `PostView`'s per-viewer fields.
///
/// - Parameters:
///   - v3: the v3 `PostView` carrying the per-viewer booleans/score.
///   - post: the already-mapped neutral `Post`, needed for `post.comments` to derive
///     `readCommentsAmount` from v3's `unread_comments`.
private func neutralPostActions(fromV3 v3: Components.Schemas.PostView, post: Post) -> PostActions {
    let myVoteScore = Int(v3.my_vote ?? 0)

    return PostActions(
        readAt: v3.read ? v3ActionSentinel : nil,
        hiddenAt: v3.hidden ? v3ActionSentinel : nil,
        savedAt: v3.saved ? v3ActionSentinel : nil,
        votedAt: myVoteScore != 0 ? v3ActionSentinel : nil,
        voteIsUpvote: myVoteScore == 0 ? nil : myVoteScore > 0,
        // v3 has no "when did you last read the comments" timestamp distinct from
        // `unread_comments` below, so this stays `nil`.
        readCommentsAt: nil,
        // `unread_comments` is how many comments v3 considers unseen; the neutral field is the
        // inverse (how many *were* seen), so it derives back to the same `unreadCommentCount` via
        // `PostView.unreadCommentCount` on the neutral side. Floored at `0` in case `unread_
        // comments` is stale and exceeds the current comment count.
        readCommentsAmount: max(0, post.comments - v3.unread_comments)
    )
}

/// Maps v3's 3-state `SubscribedType` to the neutral `FollowState`. `.approvalRequired`/
/// `.denied` are v4-only -- v3's `Pending` collapses both "awaiting mod approval" and "denied"
/// into the same case, so a v3 backend can never produce them.
private func neutralFollowState(fromV3 subscribed: Components.Schemas.SubscribedType) -> FollowState {
    switch subscribed {
    case .Subscribed:
        .accepted
    case .Pending:
        .pending
    case .NotSubscribed:
        .notFollowing
    }
}
