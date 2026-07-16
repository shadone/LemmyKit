//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Comment` for a PieFed `PiefedComment` plus its `PiefedCommentCounts`.
///
/// PieFed renames Lemmy's `content` to `body` and `creator_id` to `user_id`, matching the post
/// entity's rename (see `PiefedEntities.swift`'s header). Vote/child tallies live on the sibling
/// `counts` object, same as v3 (flattened here to match the neutral v4-shaped `Comment`). `path`
/// carries straight across unchanged -- both wire shapes use the same dot-separated materialized
/// path convention. `updatedAt` has no PieFed source: `PiefedComment` carries no `updated`/`edited`
/// timestamp of any kind, so it is always `nil` here.
func neutralComment(fromPiefed comment: PiefedComment, counts: PiefedCommentCounts) -> Comment {
    Comment(
        id: comment.id,
        postId: comment.post_id,
        creatorId: comment.user_id,
        content: comment.body,
        path: comment.path,
        removed: comment.removed,
        deleted: comment.deleted,
        distinguished: comment.distinguished,
        languageId: comment.language_id,
        publishedAt: piefedDate(comment.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        apId: comment.ap_id,
        local: comment.local,
        score: counts.score,
        upvotes: counts.upvotes,
        downvotes: counts.downvotes,
        childCount: counts.child_count
    )
}
