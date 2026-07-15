//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// "View" wrappers (post/comment/community + per-viewer state) and the top-level response
// envelopes for PieFed's `/api/alpha` read endpoints. See `PiefedEntities.swift` for the
// rationale behind keeping property names as PieFed's raw snake_case wire keys.
//
// PieFed's views are Lemmy-shaped at this level -- `subscribed` is the same three-case enum
// string (`"NotSubscribed"`/`"Subscribed"`/`"Pending"`), `saved`/`read`/`hidden` are bare bools,
// and `my_vote` is a bare `Int` score -- unlike Lemmy v4, which flattens these into
// presence-carrying timestamps. This matches Lemmy v3's shape, and the adapter layer reuses
// the same `v3ActionSentinel` bare-bool-to-sentinel-date trick v3 mapping already uses.

/// A post as seen by a particular viewer, as returned verbatim by PieFed's `/api/alpha`
/// endpoints (`post/list`, `post`).
public struct PiefedPostView: Codable, Sendable {
    public let post: PiefedPost
    public let creator: PiefedPerson
    public let community: PiefedCommunity
    public let counts: PiefedPostCounts
    /// `"NotSubscribed"` | `"Subscribed"` | `"Pending"`.
    public let subscribed: String
    public let saved: Bool
    public let read: Bool
    public let hidden: Bool
    /// The viewer's vote: `1` (upvote), `0` (none), or `-1` (downvote).
    public let my_vote: Int
    public let creator_banned_from_community: Bool
    public let creator_is_moderator: Bool
    public let creator_is_admin: Bool
    /// Present as a real `Bool` on the post-view shape (unlike `PiefedCommunityView`, whose
    /// wire shape omits this field entirely).
    public let banned_from_community: Bool?
    public let unread_comments: Int64
    /// Absent when the viewer is signed out; present (and observed always `false` so far) when
    /// signed in.
    public let creator_blocked: Bool?
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let activity_alert: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `activity_alert`.
    public let can_auth_user_moderate: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `activity_alert`.
    public let flair_list: [PiefedFlair]?
    /// Absent from `post/list` responses. Present only on some shapes (e.g. NSFW-blur state).
    public let blurred: Bool?
    /// Absent from a single-post fetch (`post/detail`'s `post_view`); present on `post/list`.
    public let filtered: Bool?
}

/// A comment as seen by a particular viewer, as returned verbatim by PieFed's `/api/alpha`
/// `comment/list` endpoint.
public struct PiefedCommentView: Codable, Sendable {
    public let comment: PiefedComment
    public let creator: PiefedPerson
    public let post: PiefedPost
    public let community: PiefedCommunity
    public let counts: PiefedCommentCounts
    public let banned_from_community: Bool
    public let subscribed: String
    public let saved: Bool
    public let creator_blocked: Bool?
    public let my_vote: Int
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let activity_alert: Bool?
    public let creator_banned_from_community: Bool
    public let creator_is_moderator: Bool
    public let creator_is_admin: Bool
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `activity_alert`.
    public let can_auth_user_moderate: Bool?
}

/// A community as seen by a particular viewer, as returned verbatim by PieFed's `/api/alpha`
/// `community/list`, `community`, and `search` endpoints.
///
/// Unlike `PiefedPostView`/`PiefedCommentView`, this wire shape has NO `banned_from_community`
/// key at all (not even `null`) -- kept `Optional` per the design contract in case a future
/// PieFed version adds it, but expect it to always decode to `nil` today.
public struct PiefedCommunityView: Codable, Sendable {
    public let community: PiefedCommunity
    public let counts: PiefedCommunityCounts
    /// `"NotSubscribed"` | `"Subscribed"` | `"Pending"`.
    public let subscribed: String
    public let blocked: Bool
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let flair_list: [PiefedFlair]?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `flair_list`.
    public let activity_alert: Bool?
    public let banned_from_community: Bool?
}

/// The instance-level site profile, as returned in `PiefedGetSiteResponse.site`.
public struct PiefedSiteView: Codable, Sendable {
    public let actor_id: String
    public let name: String
    public let description: String?
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let enable_downvotes: Bool?
    public let icon: String?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `enable_downvotes`.
    public let registration_mode: String?
    public let sidebar: String?
    public let sidebar_md: String?
    public let user_count: Int64
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `enable_downvotes`.
    public let all_languages: [PiefedLanguage]?
}

/// A person paired with their site-wide post/comment aggregates and admin standing -- the
/// shape PieFed uses both for `PiefedGetSiteResponse.admins` and `PiefedSearchResponse.users`.
public struct PiefedPersonView: Codable, Sendable {
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let activity_alert: Bool?
    public let counts: PiefedPersonCounts
    public let is_admin: Bool
    public let person: PiefedPerson
}

/// A person's site-wide post/comment aggregates, as returned in `PiefedPersonView.counts`.
public struct PiefedPersonCounts: Codable, Sendable {
    public let comment_count: Int64
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let person_id: Int64?
    public let post_count: Int64
}

/// A community paired with one of its moderators, as returned in `PiefedGetPostResponse
/// .moderators` and `PiefedGetCommunityResponse.moderators`.
public struct PiefedModeratorView: Codable, Sendable {
    public let community: PiefedCommunity
    public let moderator: PiefedPerson
}

// MARK: - Response envelopes

/// `GET /api/alpha/site`.
///
/// When the request carries an `Authorization` bearer token, PieFed adds a `my_user` embed whose
/// shape is byte-for-byte the `GET /api/alpha/user/me` response (`PiefedUserMeResponse`); it is
/// absent (decodes to nil) for a signed-out request. This is the identity source
/// `getSiteAndMyUserNeutral` reads for `.piefed` (a single authed `/site` call). Note the embed's
/// `follows` list reflects the account's live subscriptions, unlike the dedicated `user/me` route
/// whose `follows` is observed empty.
public struct PiefedGetSiteResponse: Codable, Sendable {
    public let site: PiefedSiteView
    public let admins: [PiefedPersonView]
    public let version: String
    /// The authenticated account's my-user embed, present only on an authed request; nil when
    /// signed out.
    public let my_user: PiefedUserMeResponse?
}

/// `GET /api/alpha/post/list`.
public struct PiefedGetPostsResponse: Codable, Sendable {
    public let posts: [PiefedPostView]
    public let next_page: String?
}

/// `GET /api/alpha/post`.
public struct PiefedGetPostResponse: Codable, Sendable {
    public let post_view: PiefedPostView
    /// Full views of every post cross-posted with this one, unlike `PiefedPost.cross_posts`
    /// (the lightweight per-post summary array).
    public let cross_posts: [PiefedPostView]
    public let community_view: PiefedCommunityView
    /// Not read by any neutral adapter (`getPostNeutralPiefed` only reads `post_view`/
    /// `cross_posts`) -- kept `Optional` so a future PieFed drop of this key doesn't break
    /// decoding.
    public let moderators: [PiefedModeratorView]?
}

/// `GET /api/alpha/comment/list`.
public struct PiefedGetCommentsResponse: Codable, Sendable {
    public let comments: [PiefedCommentView]
    public let next_page: String?
}

/// `GET /api/alpha/community/list`.
public struct PiefedListCommunitiesResponse: Codable, Sendable {
    public let communities: [PiefedCommunityView]
    public let next_page: String?
}

/// `GET /api/alpha/community`.
///
/// Covered by the captured fixture `piefed-community.json` (Task 5) and consumed by
/// `PiefedNeutralEndpointTests`; `getCommunityNeutralPiefed` only reads `community_view`.
public struct PiefedGetCommunityResponse: Codable, Sendable {
    public let community_view: PiefedCommunityView
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let moderators: [PiefedModeratorView]?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `moderators`.
    public let discussion_languages: [Int64]?
}

/// `GET /api/alpha/search`.
public struct PiefedSearchResponse: Codable, Sendable {
    public let posts: [PiefedPostView]
    public let comments: [PiefedCommentView]
    public let communities: [PiefedCommunityView]
    public let users: [PiefedPersonView]
    /// Echoes the request's `type_` filter (e.g. `"Communities"`, `"Posts"`, `"All"`). Not read
    /// by any neutral adapter -- kept `Optional` so a future PieFed drop of this key doesn't
    /// break decoding.
    public let type_: String?
}

/// `GET /api/alpha/resolve_object`.
///
/// Exactly one of the four fields is non-`nil` per PieFed's own live behavior (spot-checked
/// against `piefed.social`: resolving a community/person/post URL each returns a response with
/// only that one top-level key present) -- matching Lemmy's `ResolveObjectResponse` shape.
public struct PiefedResolveObjectResponse: Codable, Sendable {
    public let comment: PiefedCommentView?
    public let post: PiefedPostView?
    public let community: PiefedCommunityView?
    public let person: PiefedPersonView?
}
