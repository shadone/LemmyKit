//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Folds the neutral `PostSort` (plus an optional `.top` `TimeRange`) into PieFed's `sort` wire
/// string.
///
/// PieFed's `/api/alpha` post and community listings accept the same wire vocabulary Lemmy v3
/// does -- confirmed live against `piefed.social`: `Active`/`Hot`/`New`/`Old`/`TopSixHour`/
/// `TopTwelveHour`/`TopDay`/`TopWeek`/`TopMonth`/`TopThreeMonths`/`TopSixMonths`/`TopNineMonths`/
/// `TopYear`/`TopAll`/`MostComments`/`NewComments`/`Controversial`/`Scaled` all 200, matching v3's
/// `SortType` case names exactly. So this reuses `v3SortType(fromNeutral:timeRange:)`'s bucket
/// folding and takes its `rawValue` rather than duplicating the fold. Shared by every PieFed
/// dispatch that takes a `PostSort` (``LemmyApi/getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``,
/// ``LemmyApi/listCommunitiesNeutral(sort:pageCursor:)``, ``LemmyApi/searchNeutral(query:type:sort:timeRange:pageCursor:)``).
package func piefedSort(_ sort: PostSort, timeRange: TimeRange? = nil) -> String {
    v3SortType(fromNeutral: sort, timeRange: timeRange).rawValue
}

/// Direct, 1:1 mapping from the neutral `CommentSort` to PieFed's `sort` wire string -- reuses
/// `v3CommentSortType(fromNeutral:)`'s fold (comments have no time-bucketed sort in either API
/// version) and takes its `rawValue` rather than duplicating the case-by-case mapping. Confirmed
/// live: PieFed's `/api/alpha/comment/list` accepts the same `Hot`/`Top`/`New`/`Old`/
/// `Controversial` vocabulary as v3's `CommentSortType`.
package func piefedCommentSort(_ sort: CommentSort) -> String {
    v3CommentSortType(fromNeutral: sort).rawValue
}
