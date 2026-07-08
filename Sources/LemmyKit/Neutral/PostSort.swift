//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// The sort order for a post listing.
///
/// This is v4-shaped: time bucketing for `.top` is a **separate** `TimeRange` value passed
/// alongside the sort, unlike v3 where the bucket is fused into the sort itself (`TopDay`,
/// `TopWeek`, `TopMonth`, ...). The V3 adapter folds `.top` plus a `TimeRange` back into the
/// nearest matching v3 `SortType` bucket case (and folds a bucket-less `.top` into v3's plain
/// `TopAll`); the V4 adapter passes `sort` and `time_range_seconds` through independently.
public enum PostSort: Sendable, Equatable, CaseIterable {
    /// Posts from communities the account is most active in, weighted by recent activity.
    case active

    /// Posts ranked by Lemmy's hotness algorithm (score decayed over time).
    case hot

    /// Newest posts first.
    case new

    /// Oldest posts first.
    case old

    /// Highest-scoring posts, optionally within a `TimeRange` window.
    case top

    /// Posts with the most comments.
    case mostComments

    /// Posts with the most recent new comments.
    case newComments

    /// Posts ranked by a controversy metric (close up/downvote ratio).
    case controversial

    /// Posts ranked by a scaled ranking that normalizes for community size.
    case scaled
}
