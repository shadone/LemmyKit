//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `Post` for a v4 `Components.Schemas.Post` and, optionally, its
/// `ImageDetails`.
///
/// v4 already flattens vote/comment tallies (`score`/`upvotes`/`downvotes`/`comments`) directly
/// onto `Post`, matching the neutral shape 1:1 -- unlike v3, where they live on a separate
/// `PostAggregates` object (see `PostV3Mapping.swift`). Timestamps are parsed via `v4Date` (see
/// `V4DateParsing.swift`) since the generated type carries them as `String`, not `Date`. Like v3,
/// image pixel dimensions live on the enclosing `PostView.image_details` (not on `Post`), so the
/// caller passes them in; `imageDetails == nil` leaves `imageWidth`/`imageHeight` nil.
///
/// A handful of v4-only `Post` fields have no neutral counterpart and are dropped here:
/// `federation_pending`, `unresolved_report_count`/`report_count` (moderation-only, not part of
/// the general-purpose neutral `Post`), `embed_video_url`/`embed_video_width`/
/// `embed_video_height`, `url_content_type`, and `scheduled_publish_time_at`.
///
/// - Parameters:
///   - post: the v4 `Post`.
///   - imageDetails: the enclosing `PostView`'s `image_details`, or nil when the post has no image
///     dimensions.
func neutralPost(
    fromV4 post: LemmyKitV4Generated.Components.Schemas.Post,
    imageDetails: LemmyKitV4Generated.Components.Schemas.ImageDetails? = nil
) -> Post {
    Post(
        id: post.id,
        name: post.name,
        body: post.body,
        url: post.url,
        embedTitle: post.embed_title,
        embedDescription: post.embed_description,
        thumbnailUrl: post.thumbnail_url,
        altText: post.alt_text,
        imageWidth: imageDetails.map { Int($0.width) },
        imageHeight: imageDetails.map { Int($0.height) },
        creatorId: post.creator_id,
        communityId: post.community_id,
        apId: post.ap_id,
        local: post.local,
        nsfw: post.nsfw,
        removed: post.removed,
        deleted: post.deleted,
        locked: post.locked,
        featuredCommunity: post.featured_community,
        featuredLocal: post.featured_local,
        languageId: post.language_id,
        publishedAt: v4Date(required: post.published_at),
        updatedAt: v4Date(post.updated_at),
        newestCommentTimeAt: v4Date(post.newest_comment_time_at),
        score: post.score,
        upvotes: post.upvotes,
        downvotes: post.downvotes,
        comments: post.comments
    )
}
