//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// A "top of the last N seconds" time window, paired with `PostSort.top` to scope a top-posts
/// listing.
///
/// This mirrors v4's `time_range_seconds` query parameter, which takes an arbitrary integer
/// rather than v3's fixed set of bucketed sort cases (`TopSixHour`, `TopDay`, `TopWeek`, ...). The
/// named static constants below match v3's buckets exactly, so the V3 adapter can fold
/// `PostSort.top` plus one of these `TimeRange` values back into the corresponding v3
/// `SortType` case; an arbitrary (non-bucket) `TimeRange` has no exact v3 equivalent and is the
/// adapter's responsibility to round to the nearest bucket.
public struct TimeRange: Sendable, Equatable {
    /// The window size in seconds.
    public let seconds: Int64

    public init(seconds: Int64) {
        self.seconds = seconds
    }

    /// Matches v3's `TopSixHour` (6 * 60 * 60 seconds).
    public static let sixHours = TimeRange(seconds: 6 * 60 * 60)

    /// Matches v3's `TopTwelveHour` (12 * 60 * 60 seconds).
    public static let twelveHours = TimeRange(seconds: 12 * 60 * 60)

    /// Matches v3's `TopDay` (24 * 60 * 60 seconds).
    public static let day = TimeRange(seconds: 24 * 60 * 60)

    /// Matches v3's `TopWeek` (7 days).
    public static let week = TimeRange(seconds: 7 * 24 * 60 * 60)

    /// Matches v3's `TopMonth` (30 days).
    public static let month = TimeRange(seconds: 30 * 24 * 60 * 60)

    /// Matches v3's `TopThreeMonths` (90 days).
    public static let threeMonths = TimeRange(seconds: 90 * 24 * 60 * 60)

    /// Matches v3's `TopSixMonths` (180 days).
    public static let sixMonths = TimeRange(seconds: 180 * 24 * 60 * 60)

    /// Matches v3's `TopNineMonths` (270 days).
    public static let nineMonths = TimeRange(seconds: 270 * 24 * 60 * 60)

    /// Matches v3's `TopYear` (365 days).
    public static let year = TimeRange(seconds: 365 * 24 * 60 * 60)
}
