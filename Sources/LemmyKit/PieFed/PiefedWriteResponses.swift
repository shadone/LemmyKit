//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Write-response envelopes for PieFed's `/api/alpha` mutation endpoints (vote/save/create/edit/
// delete/follow/mark-read). PieFed's write responses embed the SAME per-viewer view shapes Phase 1
// already decodes (`PiefedPostView`/`PiefedCommentView`/`PiefedCommunityView`), so these wrappers
// only need to name the top-level key each route returns. Optionality follows the Phase-1
// alpha-drift rule; captured live against the self-hosted validation instance (PieFed 1.7.5,
// 2026-07-15) -- see `PiefedAuthDecodingTests`.

/// The wrapper returned by PieFed's post write routes (`post/like`, `post/save` (PUT),
/// `post/delete`, `post` create/edit).
///
/// The `post/like` capture returns a bare `{post_view}`; the richer `post/save`/GET-post shape can
/// also carry `cross_posts`/`community_view`/`moderators`, so those are `Optional` here (unread by
/// the write adapters, which read only `post_view`).
public struct PiefedPostResponse: Codable, Sendable {
    public let post_view: PiefedPostView
    /// Not read by any neutral adapter -- kept `Optional` so a shape that omits it (e.g. `post/like`)
    /// still decodes.
    public let cross_posts: [PiefedPostView]?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `cross_posts`.
    public let community_view: PiefedCommunityView?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `cross_posts`.
    public let moderators: [PiefedModeratorView]?
}

/// The wrapper returned by PieFed's comment write routes (`comment/like`, `comment/save` (PUT),
/// `comment/delete`, `comment` create/edit) -- a bare `{comment_view}`.
public struct PiefedCommentResponse: Codable, Sendable {
    public let comment_view: PiefedCommentView
}

/// `POST /api/alpha/community/follow` (and unfollow) response. PieFed's shape is Lemmy's
/// `CommunityResponse`. `community_view.subscribed` is the three-case string enum
/// (`"NotSubscribed"`/`"Subscribed"`/`"Pending"`), not a bool.
public struct PiefedCommunityFollowResponse: Codable, Sendable {
    public let community_view: PiefedCommunityView
    /// The community's discussion-language ids. Not read by any neutral adapter -- kept `Optional`
    /// so a future PieFed drop of this key doesn't break decoding (matches
    /// `PiefedGetCommunityResponse.discussion_languages`).
    public let discussion_languages: [Int64]?
}

/// The bare `{success}` envelope PieFed returns from routes that report only pass/fail (e.g.
/// `post/mark_as_read`).
public struct PiefedSuccessResponse: Codable, Sendable {
    public let success: Bool
}
