//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Aggregate data for a community.
public struct CommunityAggregates: Decodable {
    public let id: Int32
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
    public let hot_rank: Int32
}
