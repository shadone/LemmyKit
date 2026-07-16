//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// This file hand-decodes PieFed's `/api/alpha` JSON *exactly as PieFed sends it* --
// property names intentionally mirror PieFed's raw snake_case keys (`user_id`, `title`,
// `user_name`, `restricted_to_mods`, ...) rather than LemmyKit's neutral vocabulary. The
// PieFed-to-neutral renames (`user_id` -> `creatorId`, `title` -> `name`, `user_name` ->
// `name`, `restricted_to_mods` -> `postingRestrictedToMods`, ...) happen later, in the
// `Adapters/*PieFedMapping.swift` layer -- these types are a pure wire-format mirror.
//
// Dates are kept as `String` (not parsed into `Date` here); a later adapter parses them with
// a tolerant ISO-8601 parser (see the design doc's `piefedDate(_:)` helper). Fields observed
// absent in some `/api/alpha` response shapes (a post's embedded `community` vs. the richer
// `community_view`/`listCommunities` shape, a signed-out `creator_blocked`, etc.) are
// `Optional`, per live capture against `piefed.social` (PieFed 1.7.5, 2026-07-15).

/// A single post, as returned verbatim by PieFed's `/api/alpha` endpoints.
///
/// PieFed's post entity renames several Lemmy-required fields: the creator is `user_id` (not
/// `creator_id`), the title is `title` (not `name`), and "featured" is split into `sticky`
/// (community-level) / `instance_sticky` (instance-level) rather than Lemmy's
/// `featured_community` / `featured_local`.
public struct PiefedPost: Codable, Sendable {
    public let id: Int64
    public let user_id: Int64
    public let community_id: Int64
    public let title: String
    /// The post body, in markdown. Absent for link/image posts with no accompanying text.
    public let body: String?
    public let url: String?
    public let thumbnail_url: String?
    public let small_thumbnail_url: String?
    /// Alt text for the post's image. Only present on image posts that set one.
    public let alt_text: String?
    public let ap_id: String
    public let local: Bool
    public let nsfw: Bool
    public let removed: Bool
    public let deleted: Bool
    public let locked: Bool
    public let sticky: Bool
    public let instance_sticky: Bool
    public let language_id: Int64
    /// ISO-8601 with fractional seconds; parsed into a `Date` by the adapter layer.
    public let published: String
    public let post_type: String?
    public let ai_generated: Bool?
    public let image_details: PiefedImageDetails?
    /// Comma-separated free-text tags, or the empty string when the post has none.
    public let tags: String?
    /// The post's flair label (single string), distinct from `PiefedPostView.flair_list`
    /// (the community's full set of assignable flairs).
    public let flair: String?
    /// A lightweight per-post cross-post summary (post id + reply count + community name),
    /// distinct from `PiefedGetPostResponse.cross_posts` (full `PiefedPostView`s).
    public let cross_posts: [PiefedCrossPostSummary]?

    // Deliberately NOT decoded: `emoji_reactions` -- always `null` in every fixture captured
    // so far and its populated shape is undocumented; Codable safely ignores JSON keys with
    // no matching stored property (verified in Phase 0), so leaving it undeclared is safer
    // than guessing a type that could later throw a decode error on a real payload.
}

/// A post's vote/comment aggregates, as returned in `PiefedPostView.counts`.
public struct PiefedPostCounts: Codable, Sendable {
    /// Not read by any neutral adapter (the enclosing `PiefedPostView.post.id` is used instead)
    /// -- kept `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let post_id: Int64?
    public let comments: Int64
    public let score: Int64
    public let upvotes: Int64
    public let downvotes: Int64
    /// Not read by any neutral adapter (the enclosing post's own `published` is used for
    /// `publishedAt` instead) -- kept `Optional`, same reasoning as `post_id`.
    public let published: String?
    public let newest_comment_time: String
    /// The number of posts cross-posted from/to this one -- a count, unlike
    /// `PiefedPost.cross_posts` (the array of summaries). Not read by any neutral adapter -- kept
    /// `Optional`, same reasoning as `post_id`.
    public let cross_posts: Int64?
}

/// A person (user account), as returned verbatim by PieFed's `/api/alpha` endpoints.
///
/// PieFed's person entity renames Lemmy's `name` to `user_name`, `display_name` to `title`,
/// and `bot_account` to `bot`.
public struct PiefedPerson: Codable, Sendable {
    public let id: Int64
    public let user_name: String
    /// The person's display name. Always present (defaults to `user_name` server-side).
    public let title: String
    /// Read by `neutralPersonView(fromPiefed:)` (`isBanned`) -- required, not swept to `Optional`
    /// like the other unread fields below.
    public let banned: Bool
    public let deleted: Bool
    public let bot: Bool
    public let published: String
    public let actor_id: String
    public let local: Bool
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let instance_id: Int64?
    public let avatar: String?
    public let banner: String?
    /// Markdown bio. Only present on the richer profile shape (e.g. site admins), absent on
    /// the lightweight shape embedded in a post/comment's `creator`.
    public let about: String?
    /// HTML-rendered `about`, same presence rules.
    public let about_html: String?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `instance_id`.
    public let extra_fields: [PiefedExtraField]?
    /// The person's flair in the current community context, when applicable.
    public let flair: String?
}

/// A single custom profile field (e.g. "Pronouns: he/him"), part of `PiefedPerson.extra_fields`.
public struct PiefedExtraField: Codable, Sendable {
    public let id: Int64
    public let label: String
    public let text: String
}

/// A community, as returned verbatim by PieFed's `/api/alpha` endpoints.
///
/// PieFed's community entity renames Lemmy's `posting_restricted_to_mods` to
/// `restricted_to_mods`, and has no `visibility` field at all (Lemmy 0.19 requires it) -- the
/// adapter layer synthesizes one from `hidden`.
public struct PiefedCommunity: Codable, Sendable {
    public let id: Int64
    public let name: String
    public let title: String
    public let nsfw: Bool
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let ai_generated: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `ai_generated`.
    public let question_answer: Bool?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `ai_generated`.
    public let banned: Bool?
    public let restricted_to_mods: Bool
    public let published: String
    /// Absent on the lightweight shape embedded in a post/comment's `community`.
    public let updated: String?
    public let deleted: Bool
    public let removed: Bool
    public let actor_id: String
    public let local: Bool
    public let hidden: Bool
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `ai_generated`.
    public let instance_id: Int64?
    /// Not read by any neutral adapter (`apId` reads `actor_id` instead) -- kept `Optional`, same
    /// reasoning as `ai_generated`.
    public let ap_domain: String?
    /// Absent when the community has not set an icon.
    public let icon: String?
    /// Only present on the richer profile shape (`PiefedCommunityView`), absent on the
    /// lightweight shape embedded in a post/comment's `community`.
    public let banner: String?
    /// Markdown sidebar/description. Same presence rules as `banner`.
    public let description: String?
    /// A free-text posting warning shown to posters. Nullable and sometimes absent; both
    /// collapse to `nil` here.
    public let posting_warning: String?
}

/// A community's activity/subscription aggregates, as returned in `PiefedCommunityView.counts`.
/// Distinct shape from `PiefedPostCounts` (posts) and `PiefedCommentCounts` (comments).
public struct PiefedCommunityCounts: Codable, Sendable {
    /// Not read by any neutral adapter -- kept `Optional` so a future PieFed drop of this key
    /// doesn't break decoding.
    public let id: Int64?
    public let post_count: Int64
    public let post_reply_count: Int64
    /// PieFed's local-only subscriber count. Not read by any neutral adapter (`subscribers`
    /// reads `total_subscriptions_count` instead) -- kept `Optional`, same reasoning as `id`.
    public let subscriptions_count: Int64?
    public let total_subscriptions_count: Int64
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `id`.
    public let active_daily: Int64?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `id`.
    public let active_weekly: Int64?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `id`.
    public let active_monthly: Int64?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `id`.
    public let active_6monthly: Int64?
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `id`.
    public let published: String?
}

/// A single assignable community flair (tag), part of a `flair_list`.
public struct PiefedFlair: Codable, Sendable {
    public let id: Int64
    public let community_id: Int64
    public let flair_title: String
    public let text_color: String
    public let background_color: String
    public let blur_images: Bool
    public let ap_id: String
}

/// A comment, as returned verbatim by PieFed's `/api/alpha` endpoints.
///
/// PieFed's comment entity renames Lemmy's `content` to `body` and `creator_id` to `user_id`,
/// matching the post entity's rename. `repliesEnabled` is PieFed's own inconsistent camelCase
/// key (not `replies_enabled`) -- kept verbatim since this type mirrors the wire exactly.
public struct PiefedComment: Codable, Sendable {
    public let id: Int64
    public let user_id: Int64
    public let post_id: Int64
    public let body: String
    public let deleted: Bool
    /// Whether this comment is marked as the answer to a "question and answer" post. Not read by
    /// any neutral adapter -- kept `Optional` so a future PieFed drop of this key doesn't break
    /// decoding.
    public let answer: Bool?
    public let published: String
    public let ap_id: String
    public let local: Bool
    public let language_id: Int64
    public let distinguished: Bool
    public let locked: Bool
    public let removed: Bool
    /// Not read by any neutral adapter -- kept `Optional`, same reasoning as `answer`.
    public let repliesEnabled: Bool?
    /// Dot-separated ancestor comment id chain (Lemmy-style materialized path), e.g.
    /// `"0.123.456"`.
    public let path: String

    // Deliberately NOT decoded: `emoji_reactions` -- see the note on `PiefedPost`.
}

/// A comment's vote/reply aggregates, as returned in `PiefedCommentView.counts`.
public struct PiefedCommentCounts: Codable, Sendable {
    /// Not read by any neutral adapter (the enclosing `PiefedCommentView.comment.id` is used
    /// instead) -- kept `Optional` so a future PieFed drop of this key doesn't break decoding.
    public let comment_id: Int64?
    public let score: Int64
    public let upvotes: Int64
    public let downvotes: Int64
    /// Not read by any neutral adapter (the enclosing comment's own `published` is used for
    /// `publishedAt` instead) -- kept `Optional`, same reasoning as `comment_id`.
    public let published: String?
    public let child_count: Int64
}

/// The pixel dimensions of a post's thumbnail/linked image, when the server has them.
public struct PiefedImageDetails: Codable, Sendable {
    public let width: Int
    public let height: Int
}

/// A lightweight cross-post summary embedded in `PiefedPost.cross_posts` -- just enough to
/// link to the cross-posted thread, unlike the full `PiefedPostView`s in
/// `PiefedGetPostResponse.cross_posts`.
public struct PiefedCrossPostSummary: Codable, Sendable {
    public let post_id: Int64
    public let reply_count: Int64
    public let community_name: String
}

/// A supported UI/content language, as listed in `PiefedSiteView.all_languages`.
public struct PiefedLanguage: Codable, Sendable {
    public let code: String
    public let id: Int64
    public let name: String
}
