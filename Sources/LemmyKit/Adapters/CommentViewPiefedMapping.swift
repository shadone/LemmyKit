//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedCommentView` to the neutral, v4-shaped `CommentView` -- the "emulate
/// upward" adapter direction, the same pattern as `CommentViewV3Mapping.swift` with the smaller
/// `CommentActions` (comments have no read/hidden state or comment-thread cursor).
///
/// PieFed has no per-viewer timestamps, only bare booleans (`saved`, `creator_blocked`) and a
/// signed vote score (`my_vote`), same as v3 (see `PiefedViews.swift`'s header). Every neutral
/// `*At` field below is therefore either `nil` or `v3ActionSentinel` -- see `V3ActionSentinel.swift`.
///
/// PieFed's `PiefedCommentView.post` carries no accompanying `PiefedPostCounts` (unlike
/// `PiefedPostView`, which has its own `counts`) -- see `neutralPost(fromPiefed:)`'s (no-`counts`
/// overload) doc in `PostPiefedMapping.swift` for that narrow emulation gap.
///
/// Unlike `PiefedPostView`/`PiefedCommunityView`, `PiefedCommentView.banned_from_community` is a
/// required (non-optional) `Bool` on the wire, so it maps straight across with no coalescing.
package func neutralCommentView(fromPiefed view: PiefedCommentView) -> CommentView {
    CommentView(
        comment: neutralComment(fromPiefed: view.comment, counts: view.counts),
        creator: neutralPerson(fromPiefed: view.creator),
        post: neutralPost(fromPiefed: view.post),
        community: neutralCommunity(fromPiefed: view.community),
        creatorBannedFromCommunity: view.creator_banned_from_community,
        creatorIsModerator: view.creator_is_moderator,
        creatorIsAdmin: view.creator_is_admin,
        creatorBanned: view.banned_from_community,
        // PieFed has no equivalent of v4's `can_mod` -- no signal to derive it from, defaults to
        // `false`, same as v3.
        canMod: false,
        commentActions: neutralCommentActions(fromPiefed: view),
        communityActions: CommunityActions(followState: neutralFollowState(fromPiefedSubscribed: view.subscribed)),
        personActions: PersonActions(blockedAt: (view.creator_blocked ?? false) ? v3ActionSentinel : nil)
    )
}

/// Builds the neutral `CommentActions` for a PieFed `PiefedCommentView`'s per-viewer fields.
private func neutralCommentActions(fromPiefed view: PiefedCommentView) -> CommentActions {
    let voteScore = view.my_vote

    return CommentActions(
        savedAt: view.saved ? v3ActionSentinel : nil,
        votedAt: voteScore != 0 ? v3ActionSentinel : nil,
        voteIsUpvote: voteScore == 0 ? nil : voteScore > 0
    )
}
