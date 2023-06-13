//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/post.rs

public struct Post: Decodable {
    public let id: PostId

    public let name: String

    /// An optional link / url for the post.
    public let url: URL?

    /// An optional post body, in markdown.
    public let body: String?

    public let creator_id: PersonId

    public let community_id: CommunityId

    /// Whether the post is removed.
    public let removed: Bool

    /// Whether the post is locked.
    public let locked: Bool

    public let published: Date

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
    public let ap_id: URL

    /// Whether the post is local.
    public let local: Bool

    /// A video url for the link.
    public let embed_video_url: String?

    public let language_id: LanguageId

    /// Whether the post is featured to its community.
    public let featured_community: Bool

    /// Whether the post is featured to its site.
    public let featured_local: Bool
}