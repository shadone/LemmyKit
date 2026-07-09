//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
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
}
