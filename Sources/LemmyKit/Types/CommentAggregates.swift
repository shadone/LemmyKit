//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

public struct CommentAggregates: Decodable {
    public let id: Int32

    /// Comment identifier. The identifier is local to this instance.
    public let comment_id: CommentId

    /// Overall score of the comment.
    public let score: Int64

    /// Number of upvotes.
    public let upvotes: Int64

    /// Number of downvotes.
    public let downvotes: Int64

    /// The timestamp when the comment was published.
    public let published: Date

    /// The total number of children in this comment branch.
    public let child_count: Int32

    public let hot_rank: Int32
}
