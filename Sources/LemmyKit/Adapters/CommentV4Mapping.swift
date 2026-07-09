//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `Comment` for a v4 `Components.Schemas.Comment`.
///
/// v4 already flattens vote/child tallies (`score`/`upvotes`/`downvotes`/`child_count`) directly
/// onto `Comment`, matching the neutral shape 1:1 -- unlike v3, where they live on a separate
/// `CommentAggregates` object (see `CommentV3Mapping.swift`). Timestamps are parsed via `v4Date`
/// (see `V4DateParsing.swift`) since the generated type carries them as `String`, not `Date`.
///
/// A handful of v4-only `Comment` fields have no neutral counterpart and are dropped here:
/// `locked`, `federation_pending`, and `unresolved_report_count`/`report_count`
/// (moderation-only, not part of the general-purpose neutral `Comment`).
func neutralComment(fromV4 comment: LemmyKitV4Generated.Components.Schemas.Comment) -> Comment {
    Comment(
        id: comment.id,
        postId: comment.post_id,
        creatorId: comment.creator_id,
        content: comment.content,
        path: comment.path,
        removed: comment.removed,
        deleted: comment.deleted,
        distinguished: comment.distinguished,
        languageId: comment.language_id,
        publishedAt: v4Date(required: comment.published_at),
        updatedAt: v4Date(comment.updated_at),
        apId: comment.ap_id,
        local: comment.local,
        score: comment.score,
        upvotes: comment.upvotes,
        downvotes: comment.downvotes,
        childCount: comment.child_count
    )
}
