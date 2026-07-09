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

    func testGetPostNeutralV3ReturnsNeutralPostView() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.getPostNeutral(id: 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertTrue(postView.isSaved)
        XCTAssertEqual(postView.creator.name, "seed_mod1")
        XCTAssertEqual(postView.community.name, "music")
        XCTAssertEqual(postView.post.comments, 7)
    }

    func testGetPostNeutralV4ReturnsNeutralPostView() async throws {
        let transport = try StubTransport(responseBody: fixtureData("getPostResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.getPostNeutral(id: 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertTrue(postView.isSaved)
        XCTAssertEqual(postView.creator.name, "seed_mod1")
        XCTAssertEqual(postView.community.name, "music")
        XCTAssertEqual(postView.post.comments, 7)
    }

    /// The whole point of the neutral surface: a v3-backed and a v4-backed `LemmyApi`, given
    /// equivalent fixtures, must produce the same neutral `PostView` at the call site.
    func testV3AndV4BackendsProduceEquivalentNeutralPostView() async throws {
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

        XCTAssertEqual(fromV3.post.id, fromV4.post.id)
        XCTAssertEqual(fromV3.isSaved, fromV4.isSaved)
        XCTAssertEqual(fromV3.post.comments, fromV4.post.comments)
        XCTAssertEqual(fromV3.creator.name, fromV4.creator.name)
        XCTAssertEqual(fromV3.community.name, fromV4.community.name)
    }
}
