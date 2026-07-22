//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
import LemmyKitV4Generated
import OpenAPIRuntime
import XCTest
@testable import LemmyKit

/// A `ClientTransport` that returns a canned response for every request, regardless of what was
/// sent, so ``LemmyApi/getPostsNeutral(listingType:sort:communityId:timeRange:pageCursor:)`` and
/// ``LemmyApi/getCommentsNeutral(postId:sort:pageCursor:)`` can be exercised end-to-end (facade
/// dispatch, generated client call, JSON decode, neutral mapping, cursor pagination) without
/// hitting the network -- the same stub `GetPostNeutralTests.swift` uses.
private actor StubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// A `StubTransport` that additionally captures the outgoing request's path (which includes the
/// query string for a GET), so a listing endpoint's *request* shape (which query filter it sends)
/// can be asserted -- see `AccountFeedsNeutralTests.swift`'s transport of the same shape.
private actor PathCapturingStubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    private(set) var capturedPath: String?

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedPath = request.path

        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves the paginated neutral list endpoints end-to-end -- `getPostsNeutral` and
/// `getCommentsNeutral` -- following the vertical `GetPostNeutralTests.swift` established: facade
/// dispatch on `ApiVersion`, generated client call, neutral mapping, and (new to this pair) cursor
/// pagination emulation across the v3/v4 divide (see `Page`/`Cursor`).
final class GetListNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: getPostsNeutral

    func testGetPostsNeutralV4ReturnsItemsWithNextPage() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getPostsNeutral(listingType: .All, sort: .hot)

        XCTAssertEqual(page.items.map(\.post.id), [180, 179])
        XCTAssertTrue(page.items[0].isSaved)
        XCTAssertEqual(page.items[0].creator.name, "seed_mod1")
        XCTAssertEqual(page.items[0].community.name, "music")
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc12"))
        XCTAssertFalse(page.hasPrevPage)
    }

    func testGetPostsNeutralV3ReturnsItemsWithNilPrevPage() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostsResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getPostsNeutral(listingType: .All, sort: .hot)

        XCTAssertEqual(page.items.map(\.post.id), [180, 179, 198])
        XCTAssertEqual(page.items[0].creator.name, "seed_mod1")
        XCTAssertEqual(page.items[0].community.name, "music")
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc6"))
        // v3 has no reverse-paging cursor -- prevPage is always nil.
        XCTAssertNil(page.prevPage)
        XCTAssertFalse(page.hasPrevPage)
    }

    /// `showNsfw: true` is forwarded to v3's `getPosts` as the `show_nsfw` query param.
    func testGetPostsNeutralV3ForwardsShowNsfw() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getPostsResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.getPostsNeutral(listingType: .All, sort: .hot, showNsfw: true)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("show_nsfw=true"), "expected show_nsfw in path, got: \(path)")
    }

    /// `showNsfw: true` is forwarded to v4's `GetPosts` as the `show_nsfw` query param (v4 carries
    /// the same parameter as v3).
    func testGetPostsNeutralV4ForwardsShowNsfw() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        _ = try await api.getPostsNeutral(listingType: .All, sort: .hot, showNsfw: true)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("show_nsfw=true"), "expected show_nsfw in path, got: \(path)")
    }

    // MARK: getCommentsNeutral

    func testGetCommentsNeutralV4ReturnsPaginatedItems() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getCommentsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getCommentsNeutral(postId: 180, sort: .hot)

        XCTAssertEqual(page.items.map(\.comment.id), [501])
        XCTAssertEqual(page.items[0].comment.content, "Great track, thanks for sharing!")
        XCTAssertTrue(page.items[0].isSaved)
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc9"))
        XCTAssertFalse(page.hasPrevPage)
    }

    func testGetCommentsNeutralV3ReturnsSinglePageWithNilNextPage() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getCommentsResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getCommentsNeutral(postId: 180, sort: .hot)

        XCTAssertEqual(page.items.map(\.comment.id), [501])
        XCTAssertEqual(page.items[0].comment.content, "Great track, thanks for sharing!")
        XCTAssertTrue(page.items[0].isSaved)
        // v3's GetCommentsResponse carries no cursor at all -- always a single, complete page.
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
        XCTAssertFalse(page.hasNextPage)
        XCTAssertFalse(page.hasPrevPage)
    }

    /// The v3 post-scoped fetch must send BOTH `type_=All` and a `max_depth`.
    ///
    /// Without `max_depth`, v3's `comment/list` does not return the post's comment
    /// TREE -- it returns a flat slice of it, ordered by `sort` and bounded by the
    /// server's default `limit` (10). Most of that slice is then replies whose
    /// ancestors are absent, which a consumer threading a tree has no choice but to
    /// drop: a 135-comment post renders a handful of comments, or none at all.
    func testGetCommentsNeutralV3SendsListingTypeAndMaxDepth() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getCommentsResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.getCommentsNeutral(postId: 180, sort: .hot)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("type_=All"), "expected type_=All in path, got: \(path)")
        XCTAssertTrue(path.contains("max_depth=8"), "expected max_depth=8 in path, got: \(path)")
    }

    // MARK: getCommentsNeutral(parentId:)

    func testGetCommentsNeutralByParentV4ForwardsParentId() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getCommentsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getCommentsNeutral(parentId: 42, sort: .hot)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("parent_id=42"), "expected parent_id in path, got: \(path)")
        // Decodes and maps the same v4 fixture the post-scoped test uses.
        XCTAssertEqual(page.items.map(\.comment.id), [501])
    }

    func testGetCommentsNeutralByParentV3ForwardsParentIdAndHasNoCursor() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getCommentsResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getCommentsNeutral(parentId: 42, sort: .hot)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("parent_id=42"), "expected parent_id in path, got: \(path)")
        // v3 comment listings carry no cursor at all.
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
    }

    // MARK: Sort-fold (v3's fused `SortType`)

    /// `PostSort.top` paired with `TimeRange.week` must fold to v3's `TopWeek` -- one of v3's
    /// exact named buckets.
    func testV3SortTypeFoldsTopWithWeekToTopWeek() {
        XCTAssertEqual(v3SortType(fromNeutral: .top, timeRange: .week), .TopWeek)
    }

    /// `PostSort.top` with no `TimeRange` folds to v3's bucket-less `TopAll`.
    func testV3SortTypeFoldsTopWithNoTimeRangeToTopAll() {
        XCTAssertEqual(v3SortType(fromNeutral: .top, timeRange: nil), .TopAll)
    }

    /// An arbitrary (non-bucket) `TimeRange` rounds to the nearest v3 bucket -- 5 days is closer
    /// to `TopWeek` (7 days) than to `TopDay` (1 day).
    func testV3SortTypeRoundsArbitraryTimeRangeToNearestBucket() {
        let fiveDays = TimeRange(seconds: 5 * 24 * 60 * 60)
        XCTAssertEqual(v3SortType(fromNeutral: .top, timeRange: fiveDays), .TopWeek)
    }

    /// Non-`.top` sorts ignore `timeRange` entirely.
    func testV3SortTypeIgnoresTimeRangeForNonTopSorts() {
        XCTAssertEqual(v3SortType(fromNeutral: .hot, timeRange: .week), .Hot)
    }

    // MARK: Sort-unfold (v3/v4 `SortType` -> neutral, and the round-trip)

    /// Un-fusing each of v3's bucketed `Top<Window>` cases yields `.top` plus the matching
    /// `TimeRange`, and `TopAll` yields `.top` with no window -- and every one round-trips exactly
    /// back through `v3SortType(fromNeutral:timeRange:)`.
    func testNeutralPostSortUnfoldsV3TopBucketsAndRoundTrips() {
        let cases: [(bucket: LemmyKit.Components.Schemas.SortType, range: TimeRange?)] = [
            (.TopSixHour, .sixHours),
            (.TopTwelveHour, .twelveHours),
            (.TopDay, .day),
            (.TopWeek, .week),
            (.TopMonth, .month),
            (.TopThreeMonths, .threeMonths),
            (.TopSixMonths, .sixMonths),
            (.TopNineMonths, .nineMonths),
            (.TopYear, .year),
            (.TopAll, nil),
        ]
        for expected in cases {
            let (sort, range) = neutralPostSort(fromV3: expected.bucket)
            XCTAssertEqual(sort, .top)
            XCTAssertEqual(range, expected.range)
            XCTAssertEqual(v3SortType(fromNeutral: sort, timeRange: range), expected.bucket)
        }
    }

    /// Every non-top v3 `SortType` un-fuses to its 1:1 neutral `PostSort` with a nil `TimeRange`,
    /// and round-trips back to the same v3 case.
    func testNeutralPostSortUnfoldsV3NonTopSortsAndRoundTrips() {
        let cases: [(v3: LemmyKit.Components.Schemas.SortType, neutral: PostSort)] = [
            (.Active, .active),
            (.Hot, .hot),
            (.New, .new),
            (.Old, .old),
            (.MostComments, .mostComments),
            (.NewComments, .newComments),
            (.Controversial, .controversial),
            (.Scaled, .scaled),
        ]
        for expected in cases {
            let (sort, range) = neutralPostSort(fromV3: expected.v3)
            XCTAssertEqual(sort, expected.neutral)
            XCTAssertNil(range)
            XCTAssertEqual(v3SortType(fromNeutral: sort, timeRange: range), expected.v3)
        }
    }

    /// v4's `PostSortType` maps 1:1 to the neutral `PostSort` (v4 keeps the time window separate),
    /// and round-trips through `v4PostSortType(fromNeutral:)`.
    func testNeutralPostSortMapsV4SortTypeAndRoundTrips() {
        let cases: [(v4: LemmyKitV4Generated.Components.Schemas.PostSortType, neutral: PostSort)] = [
            (.active, .active),
            (.hot, .hot),
            (.new, .new),
            (.old, .old),
            (.top, .top),
            (.most_comments, .mostComments),
            (.new_comments, .newComments),
            (.controversial, .controversial),
            (.scaled, .scaled),
        ]
        for expected in cases {
            let neutral = neutralPostSort(fromV4: expected.v4)
            XCTAssertEqual(neutral, expected.neutral)
            XCTAssertEqual(v4PostSortType(fromNeutral: neutral), expected.v4)
        }
    }
}
