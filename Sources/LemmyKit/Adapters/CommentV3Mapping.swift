//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Comment` for a v3 `Components.Schemas.Comment` plus its
/// `CommentAggregates` ("counts").
///
/// v3 keeps vote/child tallies on a separate aggregates object; the neutral `Comment` flattens
/// them directly onto the comment (matching v4's shape -- see `Neutral/Comment.swift`'s header),
/// so `score`/`upvotes`/`downvotes`/`childCount` come from `counts` while every other field comes
/// from `comment` itself. `child_count` widens from v3's `Int32` to the neutral `Int64`.
func neutralComment(
    fromV3 comment: Components.Schemas.Comment,
    counts: Components.Schemas.CommentAggregates
) -> Comment {
    Comment(
        id: Int64(comment.id),
        postId: Int64(comment.post_id),
        creatorId: Int64(comment.creator_id),
        content: comment.content,
        path: comment.path,
        removed: comment.removed,
        deleted: comment.deleted,
        distinguished: comment.distinguished,
        languageId: Int64(comment.language_id),
        publishedAt: comment.published,
        updatedAt: comment.updated,
        apId: comment.ap_id,
        local: comment.local,
        score: counts.score,
        upvotes: counts.upvotes,
        downvotes: counts.downvotes,
        childCount: Int64(counts.child_count)
    )
}
