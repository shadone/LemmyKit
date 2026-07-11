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

/// A `ClientTransport` that returns a canned response for every request, regardless of what
/// was sent, so ``LemmyApi/getPostNeutral(id:)`` can be exercised end-to-end (facade dispatch,
/// generated client call, JSON decode, neutral mapping) without hitting the network.
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

/// Proves the first fully-callable neutral endpoint end-to-end: `LemmyApi`'s `apiVersion`
/// dispatches `getPostNeutral(id:)` to either the v3 or v4 generated client, and the extracted
/// `PostView` is mapped to the version-neutral shape -- the vertical every later endpoint
/// follows.
final class GetPostNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    func testGetPostNeutralV3ReturnsNeutralPostDetail() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let detail = try await api.getPostNeutral(id: 180)

        XCTAssertEqual(detail.post.post.id, 180)
        XCTAssertTrue(detail.post.isSaved)
        XCTAssertEqual(detail.post.creator.name, "seed_mod1")
        XCTAssertEqual(detail.post.community.name, "music")
        XCTAssertEqual(detail.post.post.comments, 7)

        // The response's cross_posts are mapped through the same PostView adapter as the main post.
        XCTAssertEqual(detail.crossPosts.map(\.post.id), [181])
        XCTAssertEqual(detail.crossPosts.first?.post.name, "Cross-post: Live recording (thread 8)")
    }

    func testGetPostNeutralV4ReturnsNeutralPostDetail() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let detail = try await api.getPostNeutral(id: 180)

        XCTAssertEqual(detail.post.post.id, 180)
        XCTAssertTrue(detail.post.isSaved)
        XCTAssertEqual(detail.post.creator.name, "seed_mod1")
        XCTAssertEqual(detail.post.community.name, "music")
        XCTAssertEqual(detail.post.post.comments, 7)

        XCTAssertEqual(detail.crossPosts.map(\.post.id), [181])
        XCTAssertEqual(detail.crossPosts.first?.post.name, "Cross-post: Live recording (thread 8)")
    }

    /// The whole point of the neutral surface: a v3-backed and a v4-backed `LemmyApi`, given
    /// equivalent fixtures, must produce the same neutral `PostDetail` at the call site --
    /// including the cross-posts.
    func testV3AndV4BackendsProduceEquivalentNeutralPostDetail() async throws {
        let v3Api = try LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: StubTransport(responseBody: fixtureData("getPostResponseV3")),
            apiVersion: .v3
        )
        let v4Api = try LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: StubTransport(responseBody: fixtureData("getPostResponseV4")),
            apiVersion: .v4
        )

        let fromV3 = try await v3Api.getPostNeutral(id: 180)
        let fromV4 = try await v4Api.getPostNeutral(id: 180)

        XCTAssertEqual(fromV3.post.post.id, fromV4.post.post.id)
        XCTAssertEqual(fromV3.post.isSaved, fromV4.post.isSaved)
        XCTAssertEqual(fromV3.post.post.comments, fromV4.post.post.comments)
        XCTAssertEqual(fromV3.post.creator.name, fromV4.post.creator.name)
        XCTAssertEqual(fromV3.post.community.name, fromV4.post.community.name)
        XCTAssertEqual(fromV3.crossPosts.map(\.post.id), fromV4.crossPosts.map(\.post.id))
    }
}
