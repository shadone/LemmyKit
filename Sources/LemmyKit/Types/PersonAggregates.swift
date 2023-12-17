//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

public struct PersonAggregates: Decodable {
    public let person_id: PersonId
    public let post_count: Int64
    public let post_score: Int64
    public let comment_count: Int64
    public let comment_score: Int64

    public init(
        person_id: PersonId,
        post_count: Int64,
        post_score: Int64,
        comment_count: Int64,
        comment_score: Int64
    ) {
        self.person_id = person_id
        self.post_count = post_count
        self.post_score = post_score
        self.comment_count = comment_count
        self.comment_score = comment_score
    }
}
