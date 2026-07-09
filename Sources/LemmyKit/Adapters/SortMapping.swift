//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// The v3 `SortType` "top" buckets, in ascending order of window size, paired with the `TimeRange`
/// they match exactly. Used both to look up an exact match and, failing that, to find the nearest
/// bucket -- see `v3TopSortType(fromTimeRange:)`.
private let v3TopBuckets: [(range: TimeRange, sortType: Components.Schemas.SortType)] = [
    (.sixHours, .TopSixHour),
    (.twelveHours, .TopTwelveHour),
    (.day, .TopDay),
    (.week, .TopWeek),
    (.month, .TopMonth),
    (.threeMonths, .TopThreeMonths),
    (.sixMonths, .TopSixMonths),
    (.nineMonths, .TopNineMonths),
    (.year, .TopYear),
]

/// Folds a `.top` sort's `TimeRange` into v3's bucketed "top" `SortType` cases. No `timeRange`
/// folds to `TopAll` (no bucket). A `timeRange` equal to one of `TimeRange`'s named constants
/// folds to the matching bucket exactly. Any other `timeRange` (an arbitrary window with no exact
/// v3 bucket) rounds to the *nearest* bucket by absolute distance in seconds -- ties break toward
/// the smaller bucket, since v3 cannot represent an arbitrary window.
private func v3TopSortType(fromTimeRange timeRange: TimeRange?) -> Components.Schemas.SortType {
    guard let timeRange else { return .TopAll }

    if let exact = v3TopBuckets.first(where: { $0.range == timeRange }) {
        return exact.sortType
    }

    // v3TopBuckets is a non-empty static literal, so `min` never returns nil.
    let nearest = v3TopBuckets.min { lhs, rhs in
        abs(lhs.range.seconds - timeRange.seconds) < abs(rhs.range.seconds - timeRange.seconds)
    }
    return nearest!.sortType
}

/// Folds the neutral `PostSort` (with its separate `TimeRange`) into v3's `SortType`, which fuses
/// the sort and the top-N time window into a single enum case (`TopDay`, `TopWeek`, ...) instead
/// of keeping them apart like v4 does. See `v3TopSortType(fromTimeRange:)` for the `.top` folding
/// rules; `timeRange` is ignored for every other sort.
package func v3SortType(fromNeutral sort: PostSort, timeRange: TimeRange?) -> Components.Schemas.SortType {
    switch sort {
    case .active: .Active
    case .hot: .Hot
    case .new: .New
    case .old: .Old
    case .mostComments: .MostComments
    case .newComments: .NewComments
    case .controversial: .Controversial
    case .scaled: .Scaled
    case .top: v3TopSortType(fromTimeRange: timeRange)
    }
}

/// Direct, 1:1 mapping from neutral `PostSort` to v4's `PostSortType` -- v4 keeps a `.top` sort's
/// time window as the separate `time_range_seconds` query parameter, so there is no bucket-folding
/// to do here (see `v3SortType(fromNeutral:timeRange:)` for the v3 side).
package func v4PostSortType(fromNeutral sort: PostSort) -> LemmyKitV4Generated.Components.Schemas.PostSortType {
    switch sort {
    case .active: .active
    case .hot: .hot
    case .new: .new
    case .old: .old
    case .top: .top
    case .mostComments: .most_comments
    case .newComments: .new_comments
    case .controversial: .controversial
    case .scaled: .scaled
    }
}

/// Direct, 1:1 mapping from neutral `CommentSort` to v3's `CommentSortType` -- comments have no
/// time-bucketed sort in either API version.
package func v3CommentSortType(fromNeutral sort: CommentSort) -> Components.Schemas.CommentSortType {
    switch sort {
    case .hot: .Hot
    case .top: .Top
    case .new: .New
    case .old: .Old
    case .controversial: .Controversial
    }
}

/// Direct, 1:1 mapping from neutral `CommentSort` to v4's `CommentSortType`.
package func v4CommentSortType(
    fromNeutral sort: CommentSort
) -> LemmyKitV4Generated.Components.Schemas.CommentSortType {
    switch sort {
    case .hot: .hot
    case .top: .top
    case .new: .new
    case .old: .old
    case .controversial: .controversial
    }
}
