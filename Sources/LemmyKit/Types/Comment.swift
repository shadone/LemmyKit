//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/comment.rs

public struct Comment: Decodable {
    /// Comment identifier. The identifier is local to this instance.
    public let id: CommentId

    /// Comment author identifier. The identifier is local to this instance.
    public let creator_id: PersonId

    /// Post identifier that the comment belongs to.
    public let post_id: PostId

    /// The content of the comment, in markdown.
    public let content: String

    /// Whether the comment is removed.
    public let removed: Bool

    /// The date this comment was published.
    public let published: Date

    /// The date this comment was last updated.
    public let updated: Date?

    /// Whether the comment is deleted.
    public let deleted: Bool

    /// The federated activity id / ap_id.
    /// e.g. `https://lemmy.world/comment/316303`
    public let ap_id: URL

    /// Whether the comment is local.
    public let local: Bool

    /// Specifies the path to this comment in a tree of comments.
    ///
    /// Represented as dot separated list of comment identifiers. The path starts with "0" representing the root.
    /// e.g. `0.219355.219732.225923`
    ///
    /// See also ``CommentPath``
    public let path: String

    public let distinguished: Bool

    /// The language of the post.
    public let language_id: LanguageId
}
