//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

public struct PostAggregates: Decodable {
    public let id: Int32

    /// Post identifier. The identifier is local to this instance.
    public let post_id: PostId

    /// Number of comments in the post.
    public let comments: Int64

    /// Overall score of the post.
    public let score: Int64

    /// Number of upvotes.
    public let upvotes: Int64

    /// Number of downvotes.
    public let downvotes: Int64

    /// The timestamp when the post was published.
    public let published: Date

    /// A newest comment time, limited to 2 days, to prevent necrobumping
    public let newest_comment_time_necro: Date

    /// The time of the newest comment in the post.
    public let newest_comment_time: Date

    /// If the post is featured on the community.
    public let featured_community: Bool

    /// If the post is featured on the site / to local.
    public let featured_local: Bool

    public let hot_rank: Int32

    public let hot_rank_active: Int32

    public init(
        id: Int32,
        post_id: PostId,
        comments: Int64,
        score: Int64,
        upvotes: Int64,
        downvotes: Int64,
        published: Date,
        newest_comment_time_necro: Date,
        newest_comment_time: Date,
        featured_community: Bool,
        featured_local: Bool,
        hot_rank: Int32,
        hot_rank_active: Int32
    ) {
        self.id = id
        self.post_id = post_id
        self.comments = comments
        self.score = score
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.published = published
        self.newest_comment_time_necro = newest_comment_time_necro
        self.newest_comment_time = newest_comment_time
        self.featured_community = featured_community
        self.featured_local = featured_local
        self.hot_rank = hot_rank
        self.hot_rank_active = hot_rank_active
    }
}
