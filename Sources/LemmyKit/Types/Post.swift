//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/post.rs

public struct Post: Decodable {
    /// Post identifier. The identifier is local to this instance.
    public let id: PostId

    /// The title of the post, in markdown.
    public let name: String

    /// An optional link / url for the post.
    public let url: LenientUrl?

    /// An optional post body, in markdown.
    public let body: String?

    /// Post author identifier. The identifier is local to this instance.
    public let creator_id: PersonId

    /// Community identifier. The identifier is local to this instance.
    public let community_id: CommunityId

    /// Whether the post is removed.
    public let removed: Bool

    /// Whether the post is locked.
    public let locked: Bool

    /// The date this post was published.
    public let published: Date

    /// The date this post was last updated.
    public let updated: Date?

    /// Whether the post is deleted.
    public let deleted: Bool

    /// Whether the post is NSFW.
    public let nsfw: Bool

    /// A title for the link.
    public let embed_title: String?

    /// A description for the link.
    public let embed_description: String?

    /// A thumbnail picture url.
    public let thumbnail_url: LenientUrl?

    /// The federated activity id / ap_id.
    /// e.g. `https://sh.itjust.works/post/109799`
    public let ap_id: URL

    /// Whether the post is local.
    public let local: Bool

    /// A video url for the link.
    public let embed_video_url: String?

    /// The language of the post.
    public let language_id: LanguageId

    /// Whether the post is featured to its community.
    public let featured_community: Bool

    /// Whether the post is featured to its site.
    public let featured_local: Bool

    public init(
        id: PostId,
        name: String,
        url: LenientUrl? = nil,
        body: String? = nil,
        creator_id: PersonId,
        community_id: CommunityId,
        removed: Bool,
        locked: Bool,
        published: Date,
        updated: Date? = nil,
        deleted: Bool,
        nsfw: Bool,
        embed_title: String? = nil,
        embed_description: String? = nil,
        thumbnail_url: LenientUrl? = nil,
        ap_id: URL,
        local: Bool,
        embed_video_url: String? = nil,
        language_id: LanguageId,
        featured_community: Bool,
        featured_local: Bool
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.body = body
        self.creator_id = creator_id
        self.community_id = community_id
        self.removed = removed
        self.locked = locked
        self.published = published
        self.updated = updated
        self.deleted = deleted
        self.nsfw = nsfw
        self.embed_title = embed_title
        self.embed_description = embed_description
        self.thumbnail_url = thumbnail_url
        self.ap_id = ap_id
        self.local = local
        self.embed_video_url = embed_video_url
        self.language_id = language_id
        self.featured_community = featured_community
        self.featured_local = featured_local
    }
}
