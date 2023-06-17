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
    public let url: URL?

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
    public let thumbnail_url: String?

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
}
