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
        XCTAssertEqual(myUser.follows.map(\.name), ["music"])
        XCTAssertEqual(myUser.moderates, [11])
    }
}
