//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// The sort order for a comment listing.
///
/// Unlike `PostSort`, comments have no `TimeRange`-bucketed variant in either API version.
public enum CommentSort: Sendable, Equatable, CaseIterable {
    /// Comments ranked by Lemmy's hotness algorithm (score decayed over time).
    case hot

    /// Highest-scoring comments first.
    case top

    /// Newest comments first.
    case new

    /// Oldest comments first.
    case old

    /// Comments ranked by a controversy metric (close up/downvote ratio).
    case controversial
}
