//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Post` for a PieFed `PiefedPost` plus its `PiefedPostCounts`.
///
/// PieFed renames several Lemmy-required fields on the post entity itself: the creator is
/// `user_id` (not `creator_id`), the title is `title` (not `name`), and "featured" is split into
/// `sticky` (community-level) / `instance_sticky` (instance-level) rather than Lemmy's
/// `featured_community` / `featured_local` -- see `PiefedEntities.swift`'s header. Vote/comment
/// tallies live on the sibling `counts` object, same as v3 (flattened here to match the neutral
/// v4-shaped `Post` -- see `Neutral/Post.swift`'s header).
///
/// Unlike v3 (whose image pixel dimensions live on the enclosing `PostView`, not `Post` itself),
/// PieFed carries `image_details`/`alt_text` directly on `PiefedPost`, so no separate parameter is
/// needed for them here. `embedTitle`/`embedDescription` (OpenGraph link-preview metadata) have no
/// PieFed source at all -- `PiefedPost` carries no such fields -- so they default to `nil`.
/// `updatedAt` also has no PieFed source: `PiefedPost` carries no `updated`/`edited` timestamp of
/// any kind (unlike `PiefedCommunity`, which does), so it is always `nil` here.
func neutralPost(fromPiefed post: PiefedPost, counts: PiefedPostCounts) -> Post {
    Post(
        id: post.id,
        name: post.title,
        body: post.body,
        url: post.url,
        embedTitle: nil,
        embedDescription: nil,
        thumbnailUrl: post.thumbnail_url,
        altText: post.alt_text,
        imageWidth: post.image_details?.width,
        imageHeight: post.image_details?.height,
        creatorId: post.user_id,
        communityId: post.community_id,
        apId: post.ap_id,
        local: post.local,
        nsfw: post.nsfw,
        removed: post.removed,
        deleted: post.deleted,
        locked: post.locked,
        featuredCommunity: post.sticky,
        featuredLocal: post.instance_sticky,
        languageId: post.language_id,
        publishedAt: piefedDate(post.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        newestCommentTimeAt: piefedDate(counts.newest_comment_time),
        score: counts.score,
        upvotes: counts.upvotes,
        downvotes: counts.downvotes,
        comments: counts.comments
    )
}

/// Builds the neutral `Post` for a PieFed `PiefedPost` with no separate `PiefedPostCounts`
/// available -- the shape of the bare `post` embedded in a `PiefedCommentView`, which (like v3's
/// `CommentView.post`) carries no accompanying aggregates for its post. `score`/`upvotes`/
/// `downvotes`/`comments` all default to `0` and `newestCommentTimeAt` to `nil` -- a known,
/// narrow emulation gap matching `neutralPost(fromV3:)`'s no-counts overload; a call site that
/// needs accurate post-level tallies from a comment context must fetch the post separately.
func neutralPost(fromPiefed post: PiefedPost) -> Post {
    Post(
        id: post.id,
        name: post.title,
        body: post.body,
        url: post.url,
        embedTitle: nil,
        embedDescription: nil,
        thumbnailUrl: post.thumbnail_url,
        altText: post.alt_text,
        imageWidth: post.image_details?.width,
        imageHeight: post.image_details?.height,
        creatorId: post.user_id,
        communityId: post.community_id,
        apId: post.ap_id,
        local: post.local,
        nsfw: post.nsfw,
        removed: post.removed,
        deleted: post.deleted,
        locked: post.locked,
        featuredCommunity: post.sticky,
        featuredLocal: post.instance_sticky,
        languageId: post.language_id,
        publishedAt: piefedDate(post.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        score: 0,
        upvotes: 0,
        downvotes: 0,
        comments: 0
    )
}
