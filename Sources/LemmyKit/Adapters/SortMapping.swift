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

/// Folds the neutral `PostSort` into v4's `CommunitySortType` for community listings
/// (``LemmyApi/listCommunitiesNeutral(sort:pageCursor:)``).
///
/// Lemmy's community listing uses a materially different sort vocabulary from post listings --
/// time-bucketed "active" variants (`active_six_months`/`active_monthly`/`active_weekly`/
/// `active_daily`), name/subscriber-count orderings, and no `top`/`controversial`/`scaled` -- so
/// this is a lossy, best-effort approximation rather than a 1:1 mapping: `.active` picks the
/// middle `active_monthly` bucket (no `TimeRange` accompanies `PostSort.active` the way one
/// optionally does `.top`, so there's no finer signal to bucket by), `.mostComments`/
/// `.newComments` both fold to `.comments` (the closest community-level analog), and anything
/// with no community-sort equivalent at all (`.top`/`.controversial`/`.scaled`) falls back to
/// `.hot`. A dedicated neutral `CommunitySort` type is a candidate follow-up if callers need the
/// fuller vocabulary.
///
/// v3's community listing reuses the same `SortType` as post listings (see
/// `v3SortType(fromNeutral:timeRange:)`), so only the v4 side needs this fold.
package func v4CommunitySortType(
    fromNeutral sort: PostSort
) -> LemmyKitV4Generated.Components.Schemas.CommunitySortType {
    switch sort {
    case .active: .active_monthly
    case .hot: .hot
    case .new: .new
    case .old: .old
    case .top: .hot
    case .mostComments: .comments
    case .newComments: .comments
    case .controversial: .hot
    case .scaled: .hot
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

/// Folds `Lemmy.ListingType` (a v3-shaped alias, see `NeutralVocabulary.swift`) into v4's
/// differently-cased `ListingType`. v4 additionally defines a `.suggested` case with no v3
/// equivalent; since a `Lemmy.ListingType` value can only ever be one of v3's four cases, this
/// fold is total and never needs to produce it.
///
/// Shared by ``LemmyApi/getPostsNeutral(listingType:sort:communityId:timeRange:pageCursor:)`` and
/// ``LemmyApi/saveUserSettingsNeutral(showNSFW:blurNSFW:defaultSortType:defaultListingType:displayName:bio:showScores:showBotAccounts:showReadPosts:showAvatars:)``.
package func v4ListingType(fromNeutral type: Lemmy.ListingType) -> LemmyKitV4Generated.Components.Schemas.ListingType {
    switch type {
    case .All: .all
    case .Local: .local
    case .Subscribed: .subscribed
    case .ModeratorView: .moderator_view
    }
}
