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
}
