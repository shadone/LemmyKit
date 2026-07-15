//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedPostView` to the neutral, v4-shaped `PostView` -- the "emulate upward"
/// adapter direction, the same pattern as `PostViewV3Mapping.swift`.
///
/// PieFed's view wrapper is Lemmy-v3-shaped at this level: bare booleans (`saved`, `read`,
/// `hidden`, `creator_blocked`) and a signed vote score (`my_vote`), not v4's per-viewer
/// timestamps (see `PiefedViews.swift`'s header). Every neutral `*At` field below is therefore
/// either `nil` (the corresponding PieFed boolean is `false`/absent) or `v3ActionSentinel` (the
/// boolean is `true`, but PieFed doesn't tell us when it became true) -- see
/// `V3ActionSentinel.swift`. Callers must read the derived `is*`/`vote`/`resolvedFollowState`
/// properties on the neutral action structs, never the raw dates.
package func neutralPostView(fromPiefed view: PiefedPostView) -> PostView {
    let post = neutralPost(fromPiefed: view.post, counts: view.counts)

    return PostView(
        post: post,
        creator: neutralPerson(fromPiefed: view.creator),
        community: neutralCommunity(fromPiefed: view.community),
        creatorBannedFromCommunity: view.creator_banned_from_community,
        creatorIsModerator: view.creator_is_moderator,
        creatorIsAdmin: view.creator_is_admin,
        // `banned_from_community` is nullable on this wire shape (absent/null on some PieFed
        // responses) -- coalesce to `false`, matching the design contract's "no ban signal" default.
        creatorBanned: view.banned_from_community ?? false,
        // PieFed has no equivalent of v4's `can_mod` (whether the viewer themself can moderate
        // this post) -- there is no PieFed signal to derive it from, so it defaults to `false`,
        // same as v3.
        canMod: false,
        postActions: neutralPostActions(fromPiefed: view, post: post),
        communityActions: CommunityActions(followState: neutralFollowState(fromPiefedSubscribed: view.subscribed)),
        personActions: PersonActions(blockedAt: (view.creator_blocked ?? false) ? v3ActionSentinel : nil)
    )
}

/// Builds the neutral `PostActions` for a PieFed `PiefedPostView`'s per-viewer fields.
///
/// - Parameters:
///   - view: the PieFed `PiefedPostView` carrying the per-viewer booleans/score.
///   - post: the already-mapped neutral `Post`, needed for `post.comments` to derive
///     `readCommentsAmount` from PieFed's `unread_comments`.
private func neutralPostActions(fromPiefed view: PiefedPostView, post: Post) -> PostActions {
    let voteScore = view.my_vote

    return PostActions(
        readAt: view.read ? v3ActionSentinel : nil,
        hiddenAt: view.hidden ? v3ActionSentinel : nil,
        savedAt: view.saved ? v3ActionSentinel : nil,
        votedAt: voteScore != 0 ? v3ActionSentinel : nil,
        voteIsUpvote: voteScore == 0 ? nil : voteScore > 0,
        // PieFed has no "when did you last read the comments" timestamp distinct from
        // `unread_comments` below, so this stays `nil`, same as v3.
        readCommentsAt: nil,
        // `unread_comments` is how many comments PieFed considers unseen; the neutral field is
        // the inverse (how many *were* seen). Floored at `0` in case `unread_comments` is stale
        // and exceeds the current comment count.
        readCommentsAmount: max(0, post.comments - view.unread_comments)
    )
}
