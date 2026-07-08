//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

/// Behavioral coverage for the version-neutral leaf value types in `Sources/LemmyKit/Neutral/`.
///
/// Pure enums with no logic (`ApiVersion`, `FollowState`, `NotificationKind`) need no test
/// beyond compiling, so they are not covered here; this file focuses on the types with actual
/// mapping/derivation behavior: `VoteDirection`'s wire-format round-trips, `Page`'s derived
/// booleans, `Cursor`'s raw-value round-trip, `TimeRange`'s named second counts, and the
/// `PostSort`/`CommentSort` case counts.
final class NeutralLeafTypesTests: XCTestCase {
    // MARK: - VoteDirection

    func testV4IsUpvoteMapping() {
        XCTAssertEqual(VoteDirection.up.v4IsUpvote, true)
        XCTAssertEqual(VoteDirection.down.v4IsUpvote, false)
        XCTAssertNil(VoteDirection.none.v4IsUpvote)
    }

    func testV3ScoreMapping() {
        XCTAssertEqual(VoteDirection.up.v3Score, 1)
        XCTAssertEqual(VoteDirection.down.v3Score, -1)
        XCTAssertEqual(VoteDirection.none.v3Score, 0)
    }

    func testFromV3ScoreReadsBackAllCases() {
        XCTAssertEqual(VoteDirection.fromV3Score(1), .up)
        XCTAssertEqual(VoteDirection.fromV3Score(42), .up)
        XCTAssertEqual(VoteDirection.fromV3Score(-1), .down)
        XCTAssertEqual(VoteDirection.fromV3Score(-42), .down)
        XCTAssertEqual(VoteDirection.fromV3Score(0), .none)
        XCTAssertEqual(VoteDirection.fromV3Score(nil), .none)
    }

    func testFromV4ReadsBackAllCases() {
        let now = Date()
        XCTAssertEqual(VoteDirection.fromV4(votedAt: now, isUpvote: true), .up)
        XCTAssertEqual(VoteDirection.fromV4(votedAt: now, isUpvote: false), .down)
        XCTAssertEqual(VoteDirection.fromV4(votedAt: now, isUpvote: nil), .none)
        // A nil votedAt means "no vote" regardless of isUpvote.
        XCTAssertEqual(VoteDirection.fromV4(votedAt: nil, isUpvote: true), .none)
        XCTAssertEqual(VoteDirection.fromV4(votedAt: nil, isUpvote: nil), .none)
    }

    func testVoteDirectionRoundTripsThroughV3ScoreAndV4IsUpvote() {
        for direction in [VoteDirection.up, .down, .none] {
            XCTAssertEqual(VoteDirection.fromV3Score(direction.v3Score), direction)
        }

        let now = Date()
        for direction in [VoteDirection.up, .down] {
            XCTAssertEqual(VoteDirection.fromV4(votedAt: now, isUpvote: direction.v4IsUpvote), direction)
        }
    }

    // MARK: - Cursor

    func testCursorRawValueRoundTrips() {
        let cursor = Cursor(rawValue: "opaque-token-123")
        XCTAssertEqual(cursor.rawValue, "opaque-token-123")
        XCTAssertEqual(cursor, Cursor(rawValue: "opaque-token-123"))
        XCTAssertNotEqual(cursor, Cursor(rawValue: "different-token"))
    }

    // MARK: - Page

    func testPageHasNextAndPrevPage() {
        let bothNil = Page<Int>(items: [1, 2, 3], nextPage: nil, prevPage: nil)
        XCTAssertFalse(bothNil.hasNextPage)
        XCTAssertFalse(bothNil.hasPrevPage)

        let nextOnly = Page<Int>(items: [1, 2, 3], nextPage: Cursor(rawValue: "next"), prevPage: nil)
        XCTAssertTrue(nextOnly.hasNextPage)
        XCTAssertFalse(nextOnly.hasPrevPage)

        let prevOnly = Page<Int>(items: [1, 2, 3], nextPage: nil, prevPage: Cursor(rawValue: "prev"))
        XCTAssertFalse(prevOnly.hasNextPage)
        XCTAssertTrue(prevOnly.hasPrevPage)

        let both = Page<Int>(
            items: [1, 2, 3],
            nextPage: Cursor(rawValue: "next"),
            prevPage: Cursor(rawValue: "prev")
        )
        XCTAssertTrue(both.hasNextPage)
        XCTAssertTrue(both.hasPrevPage)
    }

    func testPageEqualityWhenItemIsEquatable() {
        let a = Page<Int>(items: [1, 2], nextPage: Cursor(rawValue: "n"), prevPage: nil)
        let b = Page<Int>(items: [1, 2], nextPage: Cursor(rawValue: "n"), prevPage: nil)
        let c = Page<Int>(items: [1, 2], nextPage: nil, prevPage: nil)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - TimeRange

    func testTimeRangeNamedConstantsMatchV3Buckets() {
        XCTAssertEqual(TimeRange.sixHours.seconds, 6 * 60 * 60)
        XCTAssertEqual(TimeRange.twelveHours.seconds, 12 * 60 * 60)
        XCTAssertEqual(TimeRange.day.seconds, 86400)
        XCTAssertEqual(TimeRange.week.seconds, 604_800)
        XCTAssertEqual(TimeRange.month.seconds, 30 * 86400)
        XCTAssertEqual(TimeRange.threeMonths.seconds, 90 * 86400)
        XCTAssertEqual(TimeRange.sixMonths.seconds, 180 * 86400)
        XCTAssertEqual(TimeRange.nineMonths.seconds, 270 * 86400)
        XCTAssertEqual(TimeRange.year.seconds, 365 * 86400)
    }

    // MARK: - PostSort / CommentSort

    func testPostSortHasNineCases() {
        XCTAssertEqual(PostSort.allCases.count, 9)
    }

    func testCommentSortHasFiveCases() {
        XCTAssertEqual(CommentSort.allCases.count, 5)
    }
}
