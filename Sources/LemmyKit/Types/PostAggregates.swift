//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

public struct PostAggregates: Decodable {
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

    public init(
        post_id: PostId,
        comments: Int64,
        score: Int64,
        upvotes: Int64,
        downvotes: Int64,
        published: Date
    ) {
        self.post_id = post_id
        self.comments = comments
        self.score = score
        self.upvotes = upvotes
        self.downvotes = downvotes
        self.published = published
    }
}
