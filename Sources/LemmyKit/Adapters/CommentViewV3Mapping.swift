//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.CommentView` to the neutral, v4-shaped `CommentView` -- the
/// "emulate upward" adapter direction (see the Phase 5 design doc's "PostView / CommentView"
/// section), the same pattern as `PostViewV3Mapping.swift` with the smaller `CommentActions`
/// (comments have no read/hidden state or comment-thread cursor).
///
/// v3 has no per-viewer timestamps, only bare booleans (`saved`, `creator_blocked`) and a signed
/// vote score (`my_vote`). Every neutral `*At` field below is therefore either `nil` (the
/// corresponding v3 boolean is `false`/absent) or `v3ActionSentinel` (the boolean is `true`, but
/// v3 doesn't tell us when it became true) -- see `V3ActionSentinel.swift`. Callers must read the
/// derived `is*`/`vote`/`resolvedFollowState` properties on the neutral action structs, never the
/// raw dates, which is exactly what makes a v3- and a v4-backed `CommentView` read identically at
/// the call site.
///
/// v3's `CommentView.post` carries no accompanying `PostAggregates` (unlike `PostView`, which
/// has its own `counts`) -- see `neutralPost(fromV3:)`'s (no-`counts` overload) doc in
/// `PostV3Mapping.swift` for that narrow emulation gap.
package func neutralCommentView(fromV3 v3: Components.Schemas.CommentView) -> CommentView {
    CommentView(
        comment: neutralComment(fromV3: v3.comment, counts: v3.counts),
        creator: neutralPerson(fromV3: v3.creator),
        post: neutralPost(fromV3: v3.post),
        community: neutralCommunity(fromV3: v3.community),
        creatorBannedFromCommunity: v3.creator_banned_from_community,
        creatorIsModerator: v3.creator_is_moderator,
        creatorIsAdmin: v3.creator_is_admin,
        // v3's `banned_from_community` (undocumented in the spec, distinct from
        // `creator_banned_from_community` above) is the instance-wide ban flag that v4 calls
        // `creator_banned` -- same emulation as `PostViewV3Mapping.swift`.
        creatorBanned: v3.banned_from_community,
        // v3 has no equivalent of v4's `can_mod` (whether the viewer themself can moderate this
        // comment) -- there is no v3 signal to derive it from, so it defaults to `false`.
        canMod: false,
        commentActions: neutralCommentActions(fromV3: v3),
        communityActions: CommunityActions(followState: neutralFollowState(fromV3: v3.subscribed)),
        personActions: PersonActions(blockedAt: v3.creator_blocked ? v3ActionSentinel : nil)
    )
}

/// Builds the neutral `CommentActions` for a v3 `CommentView`'s per-viewer fields.
private func neutralCommentActions(fromV3 v3: Components.Schemas.CommentView) -> CommentActions {
    let myVoteScore = Int(v3.my_vote ?? 0)

    return CommentActions(
        savedAt: v3.saved ? v3ActionSentinel : nil,
        votedAt: myVoteScore != 0 ? v3ActionSentinel : nil,
        voteIsUpvote: myVoteScore == 0 ? nil : myVoteScore > 0
    )
}
