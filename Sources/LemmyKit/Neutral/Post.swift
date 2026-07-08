//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A single post, decoupled from the generated OpenAPI schema.
///
/// This is v4-shaped: vote/comment aggregates (`score`/`upvotes`/`downvotes`/`comments`) are
/// flattened directly onto the post, matching v4's `Post` schema, rather than living on a
/// separate aggregates object as in v3. A V3 backend adapter reads them from `counts` instead.
/// Per-viewer state (read/hidden/saved/vote) is intentionally NOT here — it lives on the
/// `postActions`/`personActions` carried by the composed `PostView` (built on top of this type),
/// since it depends on who is asking, not on the post itself.
public struct Post: Sendable, Equatable, Identifiable {
    /// The server-assigned post id. `Int64` (not `Int32`) for headroom even though v4's
    /// `PostId` is currently narrower on the wire.
    public let id: Int64

    /// The post's title.
    public let name: String

    /// An optional post body, in markdown.
    public let body: String?

    /// The link URL, for a link post. `nil` for a text-only post.
    public let url: String?

    /// A title scraped from the link's OpenGraph metadata, for link preview rendering.
    public let embedTitle: String?

    /// A description scraped from the link's OpenGraph metadata, for link preview rendering.
    public let embedDescription: String?

    /// A thumbnail image URL for the post, whether uploaded, scraped from a link, or generated.
    public let thumbnailUrl: String?

    /// Alt text for the post's image, when it has one.
    public let altText: String?

    /// The server id of the post's creator (`Person`).
    public let creatorId: Int64

    /// The server id of the post's community (`Community`).
    public let communityId: Int64

    /// The federated ActivityPub id of the post.
    public let apId: String

    /// Whether the post is local to this instance (as opposed to federated in from elsewhere).
    public let local: Bool

    /// Whether the post is marked NSFW.
    public let nsfw: Bool

    /// Whether the post has been removed by a moderator.
    public let removed: Bool

    /// Whether the post has been deleted by its creator.
    public let deleted: Bool

    /// Whether the post is locked (no new comments accepted).
    public let locked: Bool

    /// Whether the post is featured (pinned) to the top of its community.
    public let featuredCommunity: Bool

    /// Whether the post is featured (pinned) to the top of the whole instance.
    public let featuredLocal: Bool

    /// The id of the post's language (a Lemmy `LanguageId`; `0` means "undetermined").
    public let languageId: Int64

    /// When the post was created.
    public let publishedAt: Date

    /// When the post was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    /// The time of the newest comment in the post's thread, or `nil` if it has no comments.
    public let newestCommentTimeAt: Date?

    /// The post's score (upvotes minus downvotes).
    public let score: Int64

    /// The number of upvotes the post has received.
    public let upvotes: Int64

    /// The number of downvotes the post has received.
    public let downvotes: Int64

    /// The number of comments on the post.
    public let comments: Int64

    public init(
        id: Int64,
        name: String,
        body: String? = nil,
        url: String? = nil,
        embedTitle: String? = nil,
        embedDescription: String? = nil,
        thumbnailUrl: String? = nil,
        altText: String? = nil,
        creatorId: Int64,
        communityId: Int64,
        apId: String,
        local: Bool,
        nsfw: Bool,
        removed: Bool,
        deleted: Bool,
        locked: Bool,
        featuredCommunity: Bool,
        featuredLocal: Bool,
        languageId: Int64,
        publishedAt: Date,
        updatedAt: Date? = nil,
        newestCommentTimeAt: Date? = nil,
        score: Int64,
        upvotes: Int64,
        downvotes: Int64,
        comments: Int64
    ) {
        self.id = id
        self.name = name
        self.body = body
        self.url = url
        self.embedTitle = embedTitle
        self.embedDescription = embedDescription
        self.thumbnailUrl = thumbnailUrl
        self.altText = altText
        self.creatorId = creatorId
        self.communityId = communityId
        self.apId = apId
        self.local = local
        self.nsfw = nsfw
        self.removed = removed
        self.deleted = deleted
        self.locked = locked
        self.featuredCommunity = featuredCommunity
        self.featuredLocal = featuredLocal
        self.languageId = languageId
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.newestCommentTimeAt = newestCommentTimeAt
        self.score = score
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.comments = comments
    }
}
