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
/// sent, so ``LemmyApi/searchNeutral(query:type:sort:timeRange:pageCursor:)`` and
/// ``LemmyApi/listCommunitiesNeutral(sort:pageCursor:)`` can be exercised end-to-end (facade
/// dispatch, generated client call, JSON decode, neutral mapping) without hitting the network --
/// the same stub `GetPostNeutralTests.swift` uses.
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

/// A `ClientTransport` that additionally captures the outgoing request path (including its query
/// string), so a test can assert which query params the neutral endpoint actually sent.
private actor SearchPathCapturingTransport: ClientTransport {
    private let responseBody: Data
    private(set) var capturedPath: String?

    init(responseBody: Data) {
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedPath = request.path
        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves the read-only `searchNeutral`/`listCommunitiesNeutral` endpoints end-to-end, following
/// the `GetPostNeutralTests.swift`/`GetListNeutralTests.swift` shape: facade dispatch on
/// `ApiVersion`, generated client call, and neutral mapping -- both reusing the already-built
/// `PostView`/`CommentView`/`CommunityView`/`PersonView` mappers rather than introducing new ones.
final class SearchListNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: searchNeutral

    func testSearchNeutralV3ReturnsAllResultKindsWithNilCursors() async throws {
        let transport = try StubTransport(responseBody: fixtureData("searchResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let results = try await api.searchNeutral(query: "music", type: .all, sort: .hot)

        XCTAssertEqual(results.posts.map(\.post.id), [180])
        XCTAssertEqual(results.comments.map(\.comment.id), [501])
        XCTAssertEqual(results.communities.map(\.community.name), ["selfhosted"])
        // v3's `users` array renames to the neutral `persons`.
        XCTAssertEqual(results.persons.map(\.person.name), ["seed_mod1"])
        XCTAssertEqual(results.persons[0].postCount, 5)
        XCTAssertEqual(results.persons[0].commentCount, 12)
        // v3's `search` has no cursor of any kind -- always nil.
        XCTAssertNil(results.nextPage)
        XCTAssertNil(results.prevPage)
        XCTAssertFalse(results.hasNextPage)
        XCTAssertFalse(results.hasPrevPage)
    }

    /// A nil `sort` (the default) omits the v3 `sort` query param so the server applies its own
    /// default ordering (`Hot`), matching v4 (whose `Search` has no sort param at all); an explicit
    /// sort is still forwarded. Lets search ordering be server-owned on both backends.
    func testSearchNeutralV3OmitsSortWhenNil() async throws {
        let transport = try SearchPathCapturingTransport(responseBody: fixtureData("searchResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.searchNeutral(query: "music", type: .all)
        let nilSortPath = await transport.capturedPath
        XCTAssertNotNil(nilSortPath)
        XCTAssertFalse(
            nilSortPath!.contains("sort="),
            "nil sort must omit the sort query param, got: \(nilSortPath!)"
        )

        _ = try await api.searchNeutral(query: "music", type: .all, sort: .hot)
        let hotSortPath = await transport.capturedPath
        XCTAssertTrue(
            hotSortPath?.contains("sort=Hot") ?? false,
            "an explicit sort must still be forwarded, got: \(hotSortPath ?? "<nil>")"
        )
    }

    func testSearchNeutralV4ReturnsPersonsWithNextPageCursor() async throws {
        let transport = try StubTransport(responseBody: fixtureData("searchResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let results = try await api.searchNeutral(query: "music", type: .all, sort: .hot)

        XCTAssertEqual(results.posts.map(\.post.id), [180])
        XCTAssertEqual(results.comments.map(\.comment.id), [501])
        XCTAssertEqual(results.communities.map(\.community.name), ["music"])
        XCTAssertEqual(results.persons.map(\.person.name), ["seed_mod1"])
        XCTAssertTrue(results.persons[0].isAdmin)
        XCTAssertTrue(results.persons[0].isBanned)
        // v4 dropped `PersonAggregates` -- always nil, read `person.postCount` instead.
        XCTAssertNil(results.persons[0].postCount)
        XCTAssertEqual(results.persons[0].person.postCount, 8)
        XCTAssertTrue(results.hasNextPage)
        XCTAssertEqual(results.nextPage, Cursor(rawValue: "Pc20"))
        XCTAssertFalse(results.hasPrevPage)
    }

    // MARK: listCommunitiesNeutral

    func testListCommunitiesNeutralV3ReturnsSinglePageWithNilCursors() async throws {
        let transport = try StubTransport(responseBody: fixtureData("listCommunitiesResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.listCommunitiesNeutral(sort: .hot)

        XCTAssertEqual(page.items.map(\.community.name), ["selfhosted", "gaming", "technology"])
        // v3's `listCommunities` has no cursor of any kind -- always nil, single complete page.
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
        XCTAssertFalse(page.hasNextPage)
        XCTAssertFalse(page.hasPrevPage)
    }

    func testListCommunitiesNeutralV4ReturnsPaginatedItems() async throws {
        let transport = try StubTransport(responseBody: fixtureData("listCommunitiesResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.listCommunitiesNeutral(sort: .hot)

        XCTAssertEqual(page.items.map(\.community.name), ["music", "selfhosted"])
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc30"))
        XCTAssertFalse(page.hasPrevPage)
    }

    // MARK: Community-sort fold (v4's distinct `CommunitySortType`)

    /// Neutral `PostSort` cases with a direct v4 `CommunitySortType` equivalent fold 1:1.
    func testV4CommunitySortTypeMapsDirectEquivalents() {
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .hot), .hot)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .new), .new)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .old), .old)
    }

    /// Neutral `PostSort` cases with no `CommunitySortType` equivalent fall back to a documented
    /// best-effort approximation rather than failing.
    func testV4CommunitySortTypeApproximatesUnmatchedSorts() {
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .active), .active_monthly)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .mostComments), .comments)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .newComments), .comments)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .top), .hot)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .controversial), .hot)
        XCTAssertEqual(v4CommunitySortType(fromNeutral: .scaled), .hot)
    }
}
