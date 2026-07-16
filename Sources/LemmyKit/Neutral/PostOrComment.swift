//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A single item in a person's combined post/comment content feed, decoupled from the generated
/// OpenAPI schema.
///
/// Mirrors v4's `PostCommentCombinedView` (`ListPersonContent`'s per-item `anyOf`, discriminated
/// by a `type_` field -- see `PostCommentCombinedV4Mapping.swift`). v3 has no such combined feed
/// at all; `LemmyApi/personContentNeutral(personId:pageCursor:)`'s v3 path builds this by
/// interleaving the separate `posts[]`/`comments[]` arrays embedded in v3's `getPersonDetails`
/// response -- see that method's doc for the interleave rule.
public enum PostOrComment: Sendable, Equatable {
    /// A post in the feed.
    case post(PostView)

    /// A comment in the feed.
    case comment(CommentView)

    /// The wrapped `PostView`, or `nil` if this item is a `.comment`.
    public var post: PostView? {
        if case let .post(view) = self { view } else { nil }
    }

    /// The wrapped `CommentView`, or `nil` if this item is a `.post`.
    public var comment: CommentView? {
        if case let .comment(view) = self { view } else { nil }
    }
}

package extension PostOrComment {
    /// The item's publish date -- `PostView.post.publishedAt` for a `.post`,
    /// `CommentView.comment.publishedAt` for a `.comment`. Shared by the v3 and PieFed backends'
    /// combined-feed emulations (`LemmyApi/personContentNeutral(personId:pageCursor:)`'s v3 path,
    /// `neutralPersonContentPage(fromPiefed:)`) to interleave their separately-fetched `posts[]`/
    /// `comments[]` arrays by recency, since neither backend has a native combined feed the way v4's
    /// `ListPersonContent` does. Not public API; callers outside the package read `.post`/`.comment`
    /// and their own `publishedAt`.
    var publishedAt: Date {
        switch self {
        case let .post(view): view.post.publishedAt
        case let .comment(view): view.comment.publishedAt
        }
    }
}
