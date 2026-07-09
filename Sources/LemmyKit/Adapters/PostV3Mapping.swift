//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Post` for a v3 `Components.Schemas.Post` plus its `PostAggregates`
/// ("counts").
///
/// v3 keeps vote/comment tallies on a separate aggregates object; the neutral `Post` flattens
/// them directly onto the post (matching v4's shape -- see `Neutral/Post.swift`'s header), so
/// `score`/`upvotes`/`downvotes`/`comments` come from `counts` while every other field comes
/// from `post` itself.
func neutralPost(fromV3 post: Components.Schemas.Post, counts: Components.Schemas.PostAggregates) -> Post {
    Post(
        id: Int64(post.id),
        name: post.name,
        body: post.body,
        url: post.url,
        embedTitle: post.embed_title,
        embedDescription: post.embed_description,
        thumbnailUrl: post.thumbnail_url,
        altText: post.alt_text,
        creatorId: Int64(post.creator_id),
        communityId: Int64(post.community_id),
        apId: post.ap_id,
        local: post.local,
        nsfw: post.nsfw,
        removed: post.removed,
        deleted: post.deleted,
        locked: post.locked,
        featuredCommunity: post.featured_community,
        featuredLocal: post.featured_local,
        languageId: Int64(post.language_id),
        publishedAt: post.published,
        updatedAt: post.updated,
        // v3's `newest_comment_time` is non-optional (the server defaults it to the post's own
        // `published` time when there are no comments yet), so a v3-backed `Post` can never
        // represent "no comments yet" as `nil` here the way a v4-backed one can -- a known,
        // narrow emulation gap; `comments == 0` is the reliable way to detect "no comments".
        newestCommentTimeAt: counts.newest_comment_time,
        score: counts.score,
        upvotes: counts.upvotes,
        downvotes: counts.downvotes,
        comments: counts.comments
    )
}

/// Builds the neutral `Post` for a v3 `Components.Schemas.Post` with no separate `PostAggregates`
/// available -- the shape of the bare `post` embedded in a v3 `CommentView`, which (unlike
/// `PostView`) carries no accompanying aggregates for its post (confirmed against the `CommentView`
/// schema in `openapi.yaml`: its only aggregates object is `CommentAggregates`, for the comment
/// itself). `score`/`upvotes`/`downvotes`/`comments` all default to `0` and `newestCommentTimeAt`
/// to `nil` -- a known, narrow emulation gap; a call site that needs accurate post-level tallies
/// from a comment context must fetch the post (or its `PostView`) separately.
func neutralPost(fromV3 post: Components.Schemas.Post) -> Post {
    Post(
        id: Int64(post.id),
        name: post.name,
        body: post.body,
        url: post.url,
        embedTitle: post.embed_title,
        embedDescription: post.embed_description,
        thumbnailUrl: post.thumbnail_url,
        altText: post.alt_text,
        creatorId: Int64(post.creator_id),
        communityId: Int64(post.community_id),
        apId: post.ap_id,
        local: post.local,
        nsfw: post.nsfw,
        removed: post.removed,
        deleted: post.deleted,
        locked: post.locked,
        featuredCommunity: post.featured_community,
        featuredLocal: post.featured_local,
        languageId: Int64(post.language_id),
        publishedAt: post.published,
        updatedAt: post.updated,
        score: 0,
        upvotes: 0,
        downvotes: 0,
        comments: 0
    )
}
