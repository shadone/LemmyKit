//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/aggregates/structs.rs

public struct SiteAggregates: Decodable {
    public let id: Int32
    public let site_id: SiteId
    public let users: Int64
    public let posts: Int64
    public let comments: Int64
    public let communities: Int64

    /// The number of users with any activity in the last day.
    public let users_active_day: Int64

    /// The number of users with any activity in the last week.
    public let users_active_week: Int64

    /// The number of users with any activity in the last month.
    public let users_active_month: Int64

    /// The number of users with any activity in the last half year.
    public let users_active_half_year: Int64

    public init(
        id: Int32,
        site_id: SiteId,
        users: Int64,
        posts: Int64,
        comments: Int64,
        communities: Int64,
        users_active_day: Int64,
        users_active_week: Int64,
        users_active_month: Int64,
        users_active_half_year: Int64
    ) {
        self.id = id
        self.site_id = site_id
        self.users = users
        self.posts = posts
        self.comments = comments
        self.communities = communities
        self.users_active_day = users_active_day
        self.users_active_week = users_active_week
        self.users_active_month = users_active_month
        self.users_active_half_year = users_active_half_year
    }
}
