//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Auth + identity wire models for PieFed's `/api/alpha` write/auth surface (Phase 2). Like the
// Phase-1 read models in `PiefedEntities.swift`/`PiefedViews.swift`, these hand-decode PieFed's
// JSON *exactly as PieFed sends it* -- property names mirror PieFed's raw snake_case keys, and the
// PieFed-to-neutral renames happen later in the `Adapters/*PiefedMapping.swift` layer.
//
// Optionality follows the Phase-1 alpha-drift rule: only fields a Phase-2 adapter will actually
// consume (my-user person/counts, the `follows`/`moderates` lists, embedded view shapes, ids,
// read/saved flags, `jwt`, `success`) are required; everything else is `Optional` so a future
// PieFed drop of a key doesn't break decoding. Captured live against the self-hosted validation
// instance (PieFed 1.7.5, 2026-07-15); see `PiefedAuthDecodingTests` for the exact routes/fixtures.

/// `POST /api/alpha/user/login` success response: the bearer JWT to send on every authed request.
///
/// PieFed logs in by **username** (not email) with no 2FA field; the response `{jwt}` matches Lemmy.
public struct PiefedLoginResponse: Codable, Sendable {
    public let jwt: String
}

/// The authenticated account's saved settings, as returned in `PiefedLocalUserView.local_user`.
///
/// Every field is `Optional`: PieFed's `local_user` is a large, alpha-stage settings bag that no
/// Phase-2 adapter requires (the my-user adapter maps only the handful of preferences that exist and
/// falls back to the v3 mapping's defaults for the rest), so an added/removed/renamed setting must
/// never break decoding. Note PieFed's `local_user` carries **no `id`** -- the account's identity is
/// the enclosing `PiefedLocalUserView.person.id`.
public struct PiefedLocalUser: Codable, Sendable {
    /// `"None"` | `"Local"` | `"Trusted"` | `"All"`.
    public let accept_private_messages: String?
    /// `"Show"` | `"Blur"` | `"Hide"` | `"Transparent"`.
    public let bot_visibility: String?
    /// `"Show"` | `"Hide"` | `"Label"` | `"Transparent"`.
    public let ai_visibility: String?
    public let community_keyword_filter: [String]?
    /// `"Hot"` | `"Top"` | `"TopAll"` | `"New"` | `"Old"` | `"Controversial"`.
    public let default_comment_sort_type: String?
    /// `"All"` | `"Local"` | `"Subscribed"` | `"Popular"` | `"Moderating"` | `"ModeratorView"`.
    public let default_listing_type: String?
    /// One of PieFed's post-sort enum strings (e.g. `"Hot"`, `"New"`, `"TopDay"`).
    public let default_sort_type: String?
    public let email_unread: Bool?
    public let federate_votes: Bool?
    public let feed_auto_follow: Bool?
    public let feed_auto_leave: Bool?
    public let hide_low_quality: Bool?
    public let indexable: Bool?
    public let newsletter: Bool?
    /// `"Show"` | `"Blur"` | `"Hide"` | `"Transparent"`.
    public let nsfl_visibility: String?
    /// `"Show"` | `"Blur"` | `"Hide"` | `"Transparent"`.
    public let nsfw_visibility: String?
    public let reply_collapse_threshold: Int?
    public let reply_hide_threshold: Int?
    public let searchable: Bool?
    public let show_bot_accounts: Bool?
    public let show_nsfl: Bool?
    public let show_nsfw: Bool?
    public let show_read_posts: Bool?
    public let show_scores: Bool?
    /// Nullable on the wire; both absent and JSON-`null` collapse to `nil`.
    public let manually_approves_followers: Bool?
}

/// The authenticated account's person paired with its saved settings and site-wide aggregates, as
/// returned in `PiefedUserMeResponse.local_user_view` (and the identically-shaped `site` `my_user`
/// embed). Reuses the Phase-1 `PiefedPerson` and `PiefedPersonCounts` (a `PersonAggregates` shape).
public struct PiefedLocalUserView: Codable, Sendable {
    public let local_user: PiefedLocalUser
    public let person: PiefedPerson
    public let counts: PiefedPersonCounts
}

/// A community the authenticated account follows, as returned in the `follows` list. PieFed's shape
/// is Lemmy's `CommunityFollowerView` (`community` + `follower`).
public struct PiefedCommunityFollowerView: Codable, Sendable {
    public let community: PiefedCommunity
    /// The follower (always the requesting account). Not read by any neutral adapter -- kept
    /// `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let follower: PiefedPerson?
}

/// A community the authenticated account moderates, as returned in the `moderates` list. PieFed's
/// shape is Lemmy's `CommunityModeratorView` (`community` + `moderator`).
public struct PiefedCommunityModeratorView: Codable, Sendable {
    public let community: PiefedCommunity
    /// The moderator (always the requesting account). Not read by any neutral adapter -- kept
    /// `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let moderator: PiefedPerson?
}

/// A federated instance, as embedded in `PiefedInstanceBlockView.instance`. Minimal + fully
/// `Optional`: no Phase-2 adapter reads a blocked instance, so this only needs to decode without
/// throwing.
public struct PiefedInstance: Codable, Sendable {
    public let id: Int64?
    public let domain: String?
    public let software: String?
    public let version: String?
    public let published: String?
    public let updated: String?
}

/// A community the account has blocked, as returned in `PiefedUserMeResponse.community_blocks`. Not
/// read by any Phase-2 adapter; both sub-objects are `Optional` for maximal decode tolerance.
public struct PiefedCommunityBlockView: Codable, Sendable {
    public let community: PiefedCommunity?
    public let person: PiefedPerson?
}

/// An instance the account has blocked, as returned in `PiefedUserMeResponse.instance_blocks`. Not
/// read by any Phase-2 adapter; both sub-objects are `Optional` for maximal decode tolerance.
public struct PiefedInstanceBlockView: Codable, Sendable {
    public let instance: PiefedInstance?
    public let person: PiefedPerson?
}

/// A person the account has blocked, as returned in `PiefedUserMeResponse.person_blocks`. Not read
/// by any Phase-2 adapter; both sub-objects are `Optional` for maximal decode tolerance.
public struct PiefedPersonBlockView: Codable, Sendable {
    public let person: PiefedPerson?
    public let target: PiefedPerson?
}

/// `GET /api/alpha/user/me` (and, byte-for-byte, the `my_user` embed on an authed `GET
/// /api/alpha/site`) -- the authenticated account's identity, settings, follows, and moderated
/// communities.
///
/// - Note: PieFed's `user/me` `follows` array is observed EMPTY even while the account is subscribed
///   to communities; the populated follow list rides the `site` `my_user` embed instead (both
///   decode into this same type). The my-user adapter should therefore prefer the `site`-embed
///   source for `follows`.
public struct PiefedUserMeResponse: Codable, Sendable {
    public let local_user_view: PiefedLocalUserView
    public let follows: [PiefedCommunityFollowerView]
    public let moderates: [PiefedCommunityModeratorView]
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let community_blocks: [PiefedCommunityBlockView]?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `community_blocks`.
    public let instance_blocks: [PiefedInstanceBlockView]?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `community_blocks`.
    public let person_blocks: [PiefedPersonBlockView]?
    /// The account's enabled discussion languages (`LanguageView` shape, reusing `PiefedLanguage`).
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `community_blocks`.
    public let discussion_languages: [PiefedLanguage]?
}

/// `GET /api/alpha/user?person_id=<id>&include_content=<bool>` -- a person's profile plus (when
/// `include_content=true`) a page of their posts and comments. PieFed's shape is Lemmy's
/// `GetUserResponse`.
///
/// Reuses the Phase-1 `PiefedPersonView` (profile + aggregates), `PiefedPostView`, and
/// `PiefedCommentView`. `personDetailsNeutral`/`personContentNeutral` (Task 5) read `person_view`
/// plus `posts`/`comments`; `moderates` and `site` are unread and kept `Optional`.
public struct PiefedPersonDetailsResponse: Codable, Sendable {
    public let person_view: PiefedPersonView
    public let comments: [PiefedCommentView]
    public let posts: [PiefedPostView]
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let moderates: [PiefedCommunityModeratorView]?
    /// Present only when the caller is the profile's owner; absent otherwise. Not read by any
    /// neutral adapter -- kept `Optional`, same reasoning as `moderates`.
    public let site: PiefedSiteView?
}
