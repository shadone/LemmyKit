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
/// sent, and additionally captures the outgoing request's path (which includes the query string
/// for a GET request, see `NotificationsNeutralTests.swift`'s `PathRoutingStubTransport`) -- so a
/// read-only listing endpoint's *request* shape (which filter it sends) can be asserted, not just
/// the returned neutral view. Same shape as `GetListNeutralTests.swift`'s `StubTransport`, plus
/// path capture.
private actor CapturingStubTransport: ClientTransport {
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

/// A `ClientTransport` that fails the test if it is ever called -- used to prove the v3
/// read/hidden paths never hit the network (see their doc: v3 has no way to isolate read-only or
/// hidden-only posts, so they always return an empty page without a request).
private actor MustNotBeCalledTransport: ClientTransport {
    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        XCTFail("Expected no network request on a v3 backend")
        let response = HTTPResponse(status: .init(code: 500))
        return (response, HTTPBody("{}".data(using: .utf8)!))
    }
}

/// Proves the four account-feed neutral endpoints -- saved/read/hidden/liked -- end-to-end,
/// following the vertical `GetListNeutralTests.swift` established: facade dispatch on
/// `ApiVersion`, generated client call, neutral mapping, and (for saved/liked on v4) unwrapping
/// the combined post/comment view down to its post branch.
final class AccountFeedsNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// The path component only, stripped of its query string, so an assertion on the endpoint hit
    /// doesn't also have to spell out the whole query.
    private func pathWithoutQuery(_ path: String?) -> String? {
        path?.split(separator: "?", maxSplits: 1).first.map(String.init)
    }

    // MARK: getSavedPostsNeutral

    func testGetSavedPostsNeutralV3SendsSavedOnlyAndReturnsItems() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPostsResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getSavedPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v3/post/list")
        XCTAssertTrue(path.contains("saved_only=true"))

        XCTAssertEqual(page.items.map(\.post.id), [180, 179, 198])
        XCTAssertEqual(page.items[0].creator.name, "seed_mod1")
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc6"))
        // v3 has no reverse-paging cursor -- prevPage is always nil.
        XCTAssertNil(page.prevPage)
    }

    func testGetSavedPostsNeutralV4RequestsPostsOnlyAndReturnsItemsWithNextPage() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getSavedPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getSavedPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v4/account/saved")
        XCTAssertTrue(path.contains("type_=posts"))

        XCTAssertEqual(page.items.map(\.post.id), [180, 179])
        XCTAssertEqual(page.items[0].creator.name, "seed_mod1")
        XCTAssertEqual(page.items[0].community.name, "music")
        XCTAssertTrue(page.hasNextPage)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc20"))
        XCTAssertFalse(page.hasPrevPage)
    }

    /// v3 folds the neutral `sort` into `getPosts`'s fused `SortType` and forwards it -- `.new`
    /// becomes the `sort=New` query param.
    func testGetSavedPostsNeutralV3ForwardsSort() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPostsResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.getSavedPostsNeutral(sort: .new)

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("sort=New"), "expected sort in path, got: \(path)")
    }

    /// v4's `ListPersonSaved` has no `sort` query parameter, so a requested sort is a documented
    /// no-op -- no `sort=` appears in the outgoing request.
    func testGetSavedPostsNeutralV4IgnoresSort() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getSavedPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        _ = try await api.getSavedPostsNeutral(sort: .new)

        let path = await transport.capturedPath ?? ""
        XCTAssertFalse(path.contains("sort="), "expected no sort param on v4, got: \(path)")
    }

    // MARK: getLikedPostsNeutral

    func testGetLikedPostsNeutralV3SendsLikedOnlyAndReturnsItems() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPostsResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getLikedPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v3/post/list")
        XCTAssertTrue(path.contains("liked_only=true"))

        XCTAssertEqual(page.items.map(\.post.id), [180, 179, 198])
    }

    func testGetLikedPostsNeutralV4RequestsLikedOnlyPostsOnlyAndReturnsItems() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getSavedPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getLikedPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v4/account/liked")
        XCTAssertTrue(path.contains("like_type=liked_only"))
        XCTAssertTrue(path.contains("type_=posts"))

        XCTAssertEqual(page.items.map(\.post.id), [180, 179])
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc20"))
    }

    // MARK: getReadPostsNeutral

    func testGetReadPostsNeutralV3ReturnsEmptyPageWithNoNetworkCall() async throws {
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: MustNotBeCalledTransport(),
            apiVersion: .v3
        )

        let page = try await api.getReadPostsNeutral()

        XCTAssertEqual(page.items, [])
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
    }

    func testGetReadPostsNeutralV4ReturnsItems() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getReadPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v4/account/read")

        XCTAssertEqual(page.items.map(\.post.id), [180, 179])
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc12"))
    }

    // MARK: getHiddenPostsNeutral

    func testGetHiddenPostsNeutralV3ReturnsEmptyPageWithNoNetworkCall() async throws {
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: MustNotBeCalledTransport(),
            apiVersion: .v3
        )

        let page = try await api.getHiddenPostsNeutral()

        XCTAssertEqual(page.items, [])
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
    }

    func testGetHiddenPostsNeutralV4ReturnsItems() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPostsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getHiddenPostsNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v4/account/hidden")

        XCTAssertEqual(page.items.map(\.post.id), [180, 179])
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc12"))
    }
}
