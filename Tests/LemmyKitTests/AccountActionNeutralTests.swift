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
/// sent, and additionally captures the *outgoing* request body -- the same shape as
/// `MutationNeutralTests.swift`'s `CapturingStubTransport`.
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

/// Proves the neutral account/action endpoints end-to-end -- login, register, save settings,
/// mark-post-as-read, private messaging, and block person/community -- following the vertical
/// `GetPostNeutralTests.swift`/`MutationNeutralTests.swift` established: facade dispatch on
/// `ApiVersion`, generated client call, neutral mapping. NOTE the v3->v4 path moves for auth
/// (`/user/login` -> `/account/auth/login`, `/user/register` -> `/account/auth/register`,
/// `/user/save_user_settings` -> `/account/settings/save`) -- not directly observable through
/// this stub transport (it doesn't inspect the request path), so those are covered by reading the
/// generated client call sites instead; these tests focus on the body shape and response mapping.
final class AccountActionNeutralTests: XCTestCase {
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

    // MARK: loginNeutral

    func testLoginNeutralV3ReturnsJWT() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("loginResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let jwt = try await api.loginNeutral(usernameOrEmail: "alice", password: "hunter2")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["username_or_email"] as? String, "alice")
        XCTAssertEqual(body["password"] as? String, "hunter2")

        XCTAssertEqual(jwt, "test-jwt-token")
    }

    func testLoginNeutralV4ReturnsJWT() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("loginResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let jwt = try await api.loginNeutral(usernameOrEmail: "alice", password: "hunter2")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["username_or_email"] as? String, "alice")
        XCTAssertEqual(body["password"] as? String, "hunter2")

        XCTAssertEqual(jwt, "test-jwt-token")
    }

    // MARK: registerNeutral

    func testRegisterNeutralV3ReturnsJWT() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("loginResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let jwt = try await api.registerNeutral(username: "alice", password: "hunter2", passwordVerify: "hunter2")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["username"] as? String, "alice")

        XCTAssertEqual(jwt, "test-jwt-token")
    }

    func testRegisterNeutralV4ReturnsJWT() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("loginResponse"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let jwt = try await api.registerNeutral(username: "alice", password: "hunter2", passwordVerify: "hunter2")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["username"] as? String, "alice")

        XCTAssertEqual(jwt, "test-jwt-token")
    }

    // MARK: markPostAsReadNeutral

    /// v3's `MarkPostAsRead` request carries an *array* of post ids, even for a single post.
    func testMarkPostAsReadNeutralV3SendsPostIdsArray() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.markPostAsReadNeutral(id: 180, read: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_ids"] as? [Int], [180])
        XCTAssertEqual(body["read"] as? Bool, true)
    }

    /// v4's `MarkPostAsRead` request carries a single scalar post id, unlike v3's array, and its
    /// response is a full `PostResponse` (not a bare `SuccessResponse` like v3) -- both simply
    /// need to not throw.
    func testMarkPostAsReadNeutralV4SendsScalarPostId() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.markPostAsReadNeutral(id: 180, read: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["read"] as? Bool, true)
    }

    // MARK: createPrivateMessageNeutral

    func testCreatePrivateMessageNeutralV3SendsContentAndRecipientReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("privateMessageResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let view = try await api.createPrivateMessageNeutral(content: "Hey there!", recipientId: 20)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Hey there!")
        XCTAssertEqual(body["recipient_id"] as? Int, 20)

        XCTAssertEqual(view.privateMessage.id, 3)
        XCTAssertEqual(view.privateMessage.content, "Hey there!")
        XCTAssertEqual(view.creator.id, 14)
        XCTAssertEqual(view.recipient.id, 20)
    }

    func testCreatePrivateMessageNeutralV4SendsContentAndRecipientReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("privateMessageResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let view = try await api.createPrivateMessageNeutral(content: "Hey there!", recipientId: 20)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Hey there!")
        XCTAssertEqual(body["recipient_id"] as? Int, 20)

        XCTAssertEqual(view.privateMessage.id, 3)
        XCTAssertEqual(view.privateMessage.content, "Hey there!")
        XCTAssertEqual(view.creator.id, 14)
        XCTAssertEqual(view.recipient.id, 20)
    }

    // MARK: blockPersonNeutral

    func testBlockPersonNeutralV3SendsPersonIdAndBlockReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("blockPersonResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let view = try await api.blockPersonNeutral(id: 20, block: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["person_id"] as? Int, 20)
        XCTAssertEqual(body["block"] as? Bool, true)

        XCTAssertEqual(view.person.id, 20)
        XCTAssertEqual(view.person.name, "seed_reader")
    }

    func testBlockPersonNeutralV4SendsPersonIdAndBlockReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("personResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let view = try await api.blockPersonNeutral(id: 20, block: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["person_id"] as? Int, 20)
        XCTAssertEqual(body["block"] as? Bool, true)

        XCTAssertEqual(view.person.id, 20)
        XCTAssertEqual(view.person.name, "seed_reader")
    }

    // MARK: blockCommunityNeutral

    func testBlockCommunityNeutralV3SendsCommunityIdAndBlockReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("blockCommunityResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let view = try await api.blockCommunityNeutral(id: 29, block: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["community_id"] as? Int, 29)
        XCTAssertEqual(body["block"] as? Bool, true)

        XCTAssertEqual(view.community.id, 29)
        XCTAssertEqual(view.community.name, "music")
    }

    func testBlockCommunityNeutralV4SendsCommunityIdAndBlockReturnsNeutralView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("communityResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let view = try await api.blockCommunityNeutral(id: 29, block: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["community_id"] as? Int, 29)
        XCTAssertEqual(body["block"] as? Bool, true)

        XCTAssertEqual(view.community.id, 29)
        XCTAssertEqual(view.community.name, "music")
    }

    // MARK: saveUserSettingsNeutral

    func testSaveUserSettingsNeutralV3DoesNotThrow() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.saveUserSettingsNeutral(showNSFW: true, showReadPosts: false)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["show_nsfw"] as? Bool, true)
        XCTAssertEqual(body["show_read_posts"] as? Bool, false)
    }

    func testSaveUserSettingsNeutralV4DoesNotThrow() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.saveUserSettingsNeutral(showNSFW: true, showReadPosts: false)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["show_nsfw"] as? Bool, true)
        XCTAssertEqual(body["show_read_posts"] as? Bool, false)
    }

    /// On v3, a `.top` default sort plus a `.week` window fuses into the single `TopWeek`
    /// `SortType` case (rather than dropping the window and folding to `TopAll`).
    func testSaveUserSettingsNeutralV3FusesDefaultSortAndTimeRange() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.saveUserSettingsNeutral(defaultSortType: .top, defaultTimeRange: .week)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["default_sort_type"] as? String, "TopWeek")
    }

    /// On v4, the `.top` default sort and its `.week` window are sent independently:
    /// `default_post_sort_type` = `Top`, `default_post_time_range_seconds` = the window in seconds.
    func testSaveUserSettingsNeutralV4SendsDefaultSortAndTimeRangeSeconds() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.saveUserSettingsNeutral(defaultSortType: .top, defaultTimeRange: .week)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["default_post_sort_type"] as? String, "top")
        XCTAssertEqual(body["default_post_time_range_seconds"] as? Int, Int(TimeRange.week.seconds))
    }
}
