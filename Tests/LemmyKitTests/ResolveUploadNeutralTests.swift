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
/// sent, so ``LemmyApi/resolveObjectNeutral(query:)`` and the v4 path of
/// ``LemmyApi/uploadImageNeutral(imageData:fileName:)`` can be exercised end-to-end (facade
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

/// A `URLProtocol` that intercepts every `pictrs/image` request issued through the `.default`
/// `URLSessionConfiguration` (and therefore `URLSession.shared`), so
/// ``LemmyApi/uploadImage(imageData:fileName:mimeType:)`` -- the hand-rolled pict-rs multipart
/// upload that bypasses the generated OpenAPI client and its injectable `ClientTransport`
/// entirely -- can be exercised end-to-end without hitting the network. `uploadImageNeutral`'s v3
/// path reuses that method wholesale (see `LemmyApi+UploadImageNeutral.swift`), so this is the
/// only way to test it for real rather than only unit-testing the surrounding mapping.
///
/// Registered/unregistered per test via `URLProtocol.registerClass`/`unregisterClass`, which is
/// process-wide for the `.default` configuration. `stubbedResponse` is `nonisolated(unsafe)`
/// because `startLoading()` runs on an internal URLSession queue, but access is externally
/// serialized by each test's register-set-run-unregister sequencing, and XCTest runs the methods
/// of a single test case class serially by default.
private final class PictrsUploadStubProtocol: URLProtocol {
    nonisolated(unsafe) static var stubbedResponse: (status: Int, body: Data) = (200, Data())

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path.contains("pictrs/image") ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let (status, body) = Self.stubbedResponse
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

/// Proves the two remaining "special" neutral endpoints end-to-end, following the
/// `GetPostNeutralTests.swift`/`SearchListNeutralTests.swift` shape: facade dispatch on
/// `ApiVersion`, generated client call (or, for v3 image upload, the pre-existing hand-rolled
/// pict-rs call), and neutral mapping.
final class ResolveUploadNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: resolveObjectNeutral

    func testResolveObjectNeutralV3ReturnsPostWhenPostSet() async throws {
        let transport = try StubTransport(responseBody: fixtureData("resolveObjectResponseV3Post"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let resolved = try await api.resolveObjectNeutral(query: "https://test1.lemmy.ddenis.info/post/180")

        XCTAssertEqual(resolved?.post?.post.id, 180)
        XCTAssertNil(resolved?.comment)
        XCTAssertNil(resolved?.community)
        XCTAssertNil(resolved?.person)
    }

    func testResolveObjectNeutralV3ReturnsCommunityWhenOnlyCommunitySet() async throws {
        let transport = try StubTransport(responseBody: fixtureData("resolveObjectResponseV3Community"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let resolved = try await api.resolveObjectNeutral(query: "!selfhosted@test1.lemmy.ddenis.info")

        XCTAssertEqual(resolved?.community?.community.name, "selfhosted")
        XCTAssertNil(resolved?.post)
    }

    func testResolveObjectNeutralV3ReturnsNilWhenNothingResolved() async throws {
        let transport = try StubTransport(responseBody: fixtureData("resolveObjectResponseV3Empty"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let resolved = try await api.resolveObjectNeutral(query: "https://example.invalid/nowhere")

        XCTAssertNil(resolved)
    }

    func testResolveObjectNeutralV4ReturnsCommunity() async throws {
        let transport = try StubTransport(responseBody: fixtureData("resolveObjectResponseV4Community"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let resolved = try await api.resolveObjectNeutral(query: "!music@test1.lemmy.ddenis.info")

        XCTAssertEqual(resolved?.community?.community.name, "music")
        XCTAssertNil(resolved?.post)
        XCTAssertNil(resolved?.comment)
        XCTAssertNil(resolved?.person)
    }

    /// v4's `multi_community` variant (a community-of-communities) has no neutral counterpart --
    /// a response that resolves only that variant returns nil, same as v3's "nothing resolved"
    /// case, rather than throwing or silently mapping to the wrong kind.
    func testResolveObjectNeutralV4ReturnsNilForMultiCommunity() async throws {
        let transport = try StubTransport(responseBody: fixtureData("resolveObjectResponseV4MultiCommunity"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let resolved = try await api.resolveObjectNeutral(query: "~example@test1.lemmy.ddenis.info")

        XCTAssertNil(resolved)
    }

    // MARK: uploadImageNeutral

    func testUploadImageNeutralV4ReturnsUploadedImageFromFilenameAndImageURL() async throws {
        let responseJSON = """
            {"filename":"xyz789.png","image_url":"https://example.invalid/api/v4/image/xyz789.png"}
            """
        let transport = StubTransport(responseBody: Data(responseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            transport: transport,
            apiVersion: .v4
        )

        let uploaded = try await api.uploadImageNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "upload.png"
        )

        XCTAssertEqual(uploaded.filename, "xyz789.png")
        XCTAssertEqual(uploaded.imageURL, URL(string: "https://example.invalid/api/v4/image/xyz789.png"))
        XCTAssertNil(uploaded.deleteToken)
    }

    func testUploadImageNeutralV3ReturnsFilenameAndDeleteToken() async throws {
        let responseJSON = """
            {"files":[{"file":"abc123.jpg","delete_token":"secret-token"}],"msg":"ok"}
            """
        PictrsUploadStubProtocol.stubbedResponse = (200, Data(responseJSON.utf8))
        URLProtocol.registerClass(PictrsUploadStubProtocol.self)
        defer { URLProtocol.unregisterClass(PictrsUploadStubProtocol.self) }

        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            apiVersion: .v3
        )

        let uploaded = try await api.uploadImageNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "upload.jpg"
        )

        XCTAssertEqual(uploaded.filename, "abc123.jpg")
        XCTAssertEqual(uploaded.deleteToken, "secret-token")
        // pict-rs synthesis: instance base url + "pictrs/image" + the returned file alias.
        XCTAssertEqual(uploaded.imageURL, URL(string: "https://example.invalid/pictrs/image/abc123.jpg"))
    }
}
