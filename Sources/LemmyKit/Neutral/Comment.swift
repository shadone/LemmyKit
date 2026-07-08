//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A single comment, decoupled from the generated OpenAPI schema.
///
/// This is v4-shaped: vote aggregates (`score`/`upvotes`/`downvotes`) and `childCount` are
/// flattened directly onto the comment, matching v4's `Comment` schema, rather than living on a
/// separate aggregates object as in v3. A V3 backend adapter reads them from `counts` instead.
/// Per-viewer state (saved/vote) is intentionally NOT here — it lives on the
/// `commentActions`/`personActions` carried by the composed `CommentView` (built on top of this
/// type), since it depends on who is asking, not on the comment itself.
public struct Comment: Sendable, Equatable, Identifiable {
    /// The server-assigned comment id. `Int64` (not `Int32`) for headroom even though v4's
    /// `CommentId` is currently narrower on the wire.
    public let id: Int64

    /// The server id of the post this comment belongs to.
    public let postId: Int64

    /// The server id of the comment's creator (`Person`).
    public let creatorId: Int64

    /// The comment body, in markdown.
    public let content: String

    /// The comment's tree location, dot-separated ending with its own id, e.g. `"0.24.27"`.
    public let path: String

    /// Whether the comment has been removed by a moderator.
    public let removed: Bool

    /// Whether the comment has been deleted by its creator.
    public let deleted: Bool

    /// Whether the comment has been distinguished (marked as an official mod statement).
    public let distinguished: Bool

    /// The id of the comment's language (a Lemmy `LanguageId`; `0` means "undetermined").
    public let languageId: Int64

    /// When the comment was created.
    public let publishedAt: Date

    /// When the comment was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    /// The federated ActivityPub id of the comment.
    public let apId: String

    /// Whether the comment is local to this instance (as opposed to federated in from elsewhere).
    public let local: Bool

    /// The comment's score (upvotes minus downvotes).
    public let score: Int64

    /// The number of upvotes the comment has received.
    public let upvotes: Int64

    /// The number of downvotes the comment has received.
    public let downvotes: Int64

    /// The total number of replies in this comment's branch (its full descendant count, not
    /// just direct replies).
    public let childCount: Int64

    public init(
        id: Int64,
        postId: Int64,
        creatorId: Int64,
        content: String,
        path: String,
        removed: Bool,
        deleted: Bool,
        distinguished: Bool,
        languageId: Int64,
        publishedAt: Date,
        updatedAt: Date? = nil,
        apId: String,
        local: Bool,
        score: Int64,
        upvotes: Int64,
        downvotes: Int64,
        childCount: Int64
    ) {
        self.id = id
        self.postId = postId
        self.creatorId = creatorId
        self.content = content
        self.path = path
        self.removed = removed
        self.deleted = deleted
        self.distinguished = distinguished
        self.languageId = languageId
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.apId = apId
        self.local = local
        self.score = score
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.childCount = childCount
    }
}
