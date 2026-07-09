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
/// sent, and additionally captures the *outgoing* request body -- same shape as
/// `MutationNeutralTests.swift`'s `CapturingStubTransport`, duplicated here to keep this file
/// self-contained.
private actor CapturingStubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    private(set) var capturedRequestBodyData: Data?

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _: HTTPRequest,
        body: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        if let body {
            capturedRequestBodyData = try await Data(collecting: body, upTo: .max)
        }

        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves the neutral community endpoints end-to-end -- `followCommunityNeutral(id:follow:)` and
/// `getCommunityNeutral(id:)` -- following the vertical `GetPostNeutralTests.swift` established:
/// facade dispatch on `ApiVersion`, generated client call, neutral mapping via
/// `neutralCommunityView(fromV3:)`/`neutralCommunityView(fromV4:)`.
final class CommunityNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// Decodes the transport's captured outgoing request body as a loose JSON dictionary, so
    /// individual fields can be asserted without depending on the generated request type.
    private func capturedJSONBody(_ transport: CapturingStubTransport) async throws -> [String: Any] {
        let capturedData = await transport.capturedRequestBodyData
        let data = try XCTUnwrap(capturedData)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: followCommunityNeutral

    func testFollowCommunityNeutralV3SendsFollowTrueAndReturnsAcceptedFollowState() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("followCommunityResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let communityView = try await api.followCommunityNeutral(id: 29, follow: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["follow"] as? Bool, true)
        XCTAssertEqual(body["community_id"] as? Int, 29)

        XCTAssertEqual(communityView.community.id, 29)
        XCTAssertEqual(communityView.followState, .accepted)
    }

    func testFollowCommunityNeutralV4SendsFollowTrueAndReturnsAcceptedFollowState() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("followCommunityResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let communityView = try await api.followCommunityNeutral(id: 29, follow: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["follow"] as? Bool, true)
        XCTAssertEqual(body["community_id"] as? Int, 29)

        XCTAssertEqual(communityView.community.id, 29)
        XCTAssertEqual(communityView.followState, .accepted)
    }

    func testFollowCommunityNeutralV3SendsFollowFalse() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("followCommunityResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.followCommunityNeutral(id: 29, follow: false)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["follow"] as? Bool, false)
    }

    // MARK: getCommunityNeutral

    func testGetCommunityNeutralV3ReturnsNeutralCommunityView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getCommunityResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let communityView = try await api.getCommunityNeutral(id: 29)

        XCTAssertEqual(communityView.community.id, 29)
        XCTAssertEqual(communityView.community.name, "music")
        XCTAssertEqual(communityView.community.subscribers, 10)
        XCTAssertEqual(communityView.followState, .notFollowing)
        XCTAssertFalse(communityView.isBlocked)
        XCTAssertFalse(communityView.canMod)
    }

    func testGetCommunityNeutralV4ReturnsNeutralCommunityView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getCommunityResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let communityView = try await api.getCommunityNeutral(id: 29)

        XCTAssertEqual(communityView.community.id, 29)
        XCTAssertEqual(communityView.community.name, "music")
        XCTAssertEqual(communityView.community.subscribers, 100)
        XCTAssertEqual(communityView.followState, .notFollowing)
        XCTAssertFalse(communityView.isBlocked)
        XCTAssertFalse(communityView.canMod)
    }

    /// v3's `CommunityView.blocked` maps to the neutral `CommunityView.isBlocked` via
    /// `CommunityActions.blockedAt` (a `v3ActionSentinel`, since v3 carries no timestamp).
    func testGetCommunityNeutralV3BlockedReturnsIsBlockedTrue() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getCommunityResponseV3Blocked"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let communityView = try await api.getCommunityNeutral(id: 29)

        XCTAssertTrue(communityView.isBlocked)
    }

    /// The whole point of the neutral surface: a v3-backed and a v4-backed `LemmyApi`, given
    /// equivalent fixtures, must produce the same neutral `CommunityView` at the call site.
    func testV3AndV4BackendsProduceEquivalentNeutralCommunityView() async throws {
        let v3Api = try LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: CapturingStubTransport(responseBody: fixtureData("getCommunityResponseV3")),
            apiVersion: .v3
        )
        let v4Api = try LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: CapturingStubTransport(responseBody: fixtureData("getCommunityResponseV4")),
            apiVersion: .v4
        )

        let fromV3 = try await v3Api.getCommunityNeutral(id: 29)
        let fromV4 = try await v4Api.getCommunityNeutral(id: 29)

        XCTAssertEqual(fromV3.community.id, fromV4.community.id)
        XCTAssertEqual(fromV3.community.name, fromV4.community.name)
        XCTAssertEqual(fromV3.followState, fromV4.followState)
        XCTAssertEqual(fromV3.isBlocked, fromV4.isBlocked)
        XCTAssertEqual(fromV3.canMod, fromV4.canMod)
    }
}
