//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

/// Aggregate data for a community.
public struct CommunityAggregates: Decodable {
    public let community_id: CommunityId
    public let subscribers: Int64
    public let posts: Int64
    public let comments: Int64
    public let published: Date
    /// The number of users with any activity in the last day.
    public let users_active_day: Int64
    /// The number of users with any activity in the last week.
    public let users_active_week: Int64
    /// The number of users with any activity in the last month.
    public let users_active_month: Int64
    /// The number of users with any activity in the last year.com
    public let users_active_half_year: Int64

    public init(
        community_id: CommunityId,
        subscribers: Int64,
        posts: Int64,
        comments: Int64,
        published: Date,
        users_active_day: Int64,
        users_active_week: Int64,
        users_active_month: Int64,
        users_active_half_year: Int64
    ) {
        self.community_id = community_id
        self.subscribers = subscribers
        self.posts = posts
        self.comments = comments
        self.published = published
        self.users_active_day = users_active_day
        self.users_active_week = users_active_week
        self.users_active_month = users_active_month
        self.users_active_half_year = users_active_half_year
    }
}
