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
/// sent. Mirrors `GetPostNeutralTests.StubTransport` -- see that file for the rationale.
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

/// A `ClientTransport` that routes a canned JSON body per generated `operationID` and TALLIES how
/// many times each operation was invoked -- so a combined neutral call can be asserted to issue the
/// exact set of HTTP round-trips expected (e.g. a v3 combined site+account fetch hits `getSite`
/// exactly once; a v4 one hits both `GetSite` and `GetMyUser`). An operation with no registered
/// body falls back to `{}`.
private actor RoutingCountingTransport: ClientTransport {
    private let bodies: [String: Data]
    private(set) var counts: [String: Int] = [:]

    init(bodies: [String: Data]) {
        self.bodies = bodies
    }

    func count(for operationID: String) -> Int {
        counts[operationID] ?? 0
    }

    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        counts[operationID, default: 0] += 1
        let data = bodies[operationID] ?? Data("{}".utf8)
        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(data))
    }
}

/// Exercises the v3/v4 dispatch for ``LemmyApi/getSiteNeutral()`` and
/// ``LemmyApi/getMyUserNeutral()`` -- the "my_user split" v4 introduces by removing `my_user`
/// from `GetSiteResponse` in favor of a separate `GET /api/v4/account` operation.
final class SiteMyUserNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: getSiteNeutral

    func testGetSiteNeutralV3ReturnsSiteInfoWithTaglineAndNoMyUser() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getSiteResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let siteInfo = try await api.getSiteNeutral()

        XCTAssertEqual(siteInfo.version, "0.19.18")
        // v3's `taglines` is a rotating list; the neutral `tagline` takes the first entry.
        XCTAssertEqual(siteInfo.tagline, "Welcome to test1!")
        XCTAssertEqual(siteInfo.site.id, 1)
        XCTAssertEqual(siteInfo.site.name, "test1")
        XCTAssertEqual(siteInfo.site.summary, "A short summary of test1")
        XCTAssertEqual(siteInfo.site.posts, 79)
        XCTAssertEqual(siteInfo.site.users, 11)
        XCTAssertEqual(siteInfo.admins.map(\.name), ["admin"])
        // `SiteInfo` has no `myUser` property at all -- enforced at compile time by its shape
        // (see `Neutral/SiteInfo.swift`) even though the v3 fixture's raw response carries one.
    }

    func testGetSiteNeutralV4ReturnsSiteInfoWithSingleTagline() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getSiteResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let siteInfo = try await api.getSiteNeutral()

        XCTAssertEqual(siteInfo.version, "1.0.0-pre")
        XCTAssertEqual(siteInfo.tagline, "Welcome to test1!")
        XCTAssertEqual(siteInfo.site.id, 1)
        XCTAssertEqual(siteInfo.site.name, "test1")
        XCTAssertEqual(siteInfo.site.summary, "A short summary of test1")
        XCTAssertEqual(siteInfo.site.posts, 79)
        XCTAssertEqual(siteInfo.site.users, 11)
        XCTAssertEqual(siteInfo.admins.map(\.name), ["admin"])
    }

    // MARK: getMyUserNeutral

    func testGetMyUserNeutralV4ReturnsMyUserFromAccountEndpoint() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getMyUserResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let myUser = try await api.getMyUserNeutral()

        XCTAssertEqual(myUser.person.name, "john")
        XCTAssertEqual(myUser.localUserId, 2)
        XCTAssertEqual(myUser.email, "john@example.invalid")
        XCTAssertTrue(myUser.emailVerified)
        XCTAssertTrue(myUser.acceptedApplication)
        XCTAssertFalse(myUser.isAdmin)
        XCTAssertTrue(myUser.showNsfw)
        XCTAssertTrue(myUser.blurNsfw)
        XCTAssertFalse(myUser.showScores)
        XCTAssertEqual(myUser.defaultListingType, .Subscribed)
        // v4 keeps the default sort and its window apart: `default_post_sort_type` = "top" and the
        // separate `default_post_time_range_seconds` = 604800 (one week).
        XCTAssertEqual(myUser.defaultSort, .top)
        XCTAssertEqual(myUser.defaultTimeRange, .week)
        XCTAssertEqual(myUser.follows.map(\.name), ["music"])
        XCTAssertEqual(myUser.moderates, [11])
    }

    func testGetMyUserNeutralV3ExtractsMyUserFromGetSite() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getSiteResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let myUser = try await api.getMyUserNeutral()

        XCTAssertEqual(myUser.person.name, "john")
        XCTAssertEqual(myUser.localUserId, 2)
        XCTAssertEqual(myUser.email, "john@example.invalid")
        XCTAssertTrue(myUser.emailVerified)
        XCTAssertTrue(myUser.acceptedApplication)
        XCTAssertFalse(myUser.isAdmin)
        XCTAssertTrue(myUser.showNsfw)
        XCTAssertTrue(myUser.blurNsfw)
        XCTAssertFalse(myUser.showScores)
        XCTAssertEqual(myUser.defaultListingType, .Subscribed)
        // v3 fuses the sort and its window into one `SortType`; "TopWeek" un-fuses to `.top` plus
        // a one-week `TimeRange`.
        XCTAssertEqual(myUser.defaultSort, .top)
        XCTAssertEqual(myUser.defaultTimeRange, .week)
        XCTAssertEqual(myUser.follows.map(\.name), ["music"])
        XCTAssertEqual(myUser.moderates, [11])
    }

    // MARK: getSiteAndMyUserNeutral

    /// On v3 the combined call must issue EXACTLY ONE `getSite` round-trip -- decoding both the
    /// site and the account's `my_user` from that single `GetSiteResponse` -- rather than the two
    /// full `getSite` fetches that calling `getSiteNeutral()` then `getMyUserNeutral()` would incur.
    func testGetSiteAndMyUserNeutralV3IssuesExactlyOneGetSiteRequest() async throws {
        let transport = try RoutingCountingTransport(
            bodies: ["getSite": fixtureData("getSiteResponseV3")]
        )
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let result = try await api.getSiteAndMyUserNeutral()

        // The single-fetch guarantee: one and only one getSite HTTP request.
        let getSiteCount = await transport.count(for: "getSite")
        XCTAssertEqual(getSiteCount, 1)

        // Both halves decoded from that one response.
        XCTAssertEqual(result.site.version, "0.19.18")
        XCTAssertEqual(result.site.site.name, "test1")
        XCTAssertEqual(result.myUser?.person.name, "john")
        XCTAssertEqual(result.myUser?.localUserId, 2)
        XCTAssertEqual(result.myUser?.defaultSort, .top)
        XCTAssertEqual(result.myUser?.defaultTimeRange, .week)
    }

    /// On v4 the combined call hits BOTH native endpoints -- `GetSite` and `GetMyUser` -- since v4
    /// removed `my_user` from the site response; each exactly once.
    func testGetSiteAndMyUserNeutralV4HitsBothNativeEndpoints() async throws {
        let transport = try RoutingCountingTransport(
            bodies: [
                "GetSite": fixtureData("getSiteResponseV4"),
                "GetMyUser": fixtureData("getMyUserResponseV4"),
            ]
        )
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let result = try await api.getSiteAndMyUserNeutral()

        let getSiteCount = await transport.count(for: "GetSite")
        let getMyUserCount = await transport.count(for: "GetMyUser")
        XCTAssertEqual(getSiteCount, 1)
        XCTAssertEqual(getMyUserCount, 1)

        XCTAssertEqual(result.site.version, "1.0.0-pre")
        XCTAssertEqual(result.myUser?.person.name, "john")
        XCTAssertEqual(result.myUser?.defaultSort, .top)
        XCTAssertEqual(result.myUser?.defaultTimeRange, .week)
    }
}
