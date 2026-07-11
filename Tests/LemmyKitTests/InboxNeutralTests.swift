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
/// sent, and additionally captures the *outgoing* request path -- including its query string --
/// so a query-parameter filter (like `listNotificationsNeutral`'s `kind` on v4) can be asserted
/// without depending on the generated request type. Same shape as `MutationNeutralTests.swift`'s
/// body-capturing `CapturingStubTransport`, but capturing the request path instead of the body.
private actor PathCapturingStubTransport: ClientTransport {
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

/// A `ClientTransport` that returns a canned response for every request, regardless of what was
/// sent, and additionally captures the *outgoing* request body -- so a mutation neutral
/// endpoint's write direction can be asserted, not only the returned neutral value. Same shape as
/// `MutationNeutralTests.swift`'s `CapturingStubTransport`.
private actor BodyCapturingStubTransport: ClientTransport {
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

/// A `ClientTransport` that routes by request path and fails the test on any request whose path
/// isn't one of the expected ones -- used to prove a kind-filtered v3 fan-out calls *only* the
/// endpoint(s) its `kind` maps to, not the other two. Same shape as
/// `NotificationsNeutralTests.swift`'s `PathRoutingStubTransport`.
private actor PathRoutingStubTransport: ClientTransport {
    private let responseBodiesByPath: [String: Data]

    init(responseBodiesByPath: [String: Data]) {
        self.responseBodiesByPath = responseBodiesByPath
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        // `request.path` includes the query string (e.g. "...?unread_only=false") -- match on
        // just the path component, before any "?".
        let pathWithoutQuery = request.path?.split(separator: "?", maxSplits: 1).first.map(String.init)
        guard let pathWithoutQuery, let responseBody = responseBodiesByPath[pathWithoutQuery] else {
            XCTFail("Unexpected request path: \(request.path ?? "<nil>")")
            let response = HTTPResponse(status: .init(code: 404))
            return (response, HTTPBody("{}".data(using: .utf8)!))
        }

        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves the neutral INBOX surface added as a follow-up to the unified-inbox `listNotificationsNeutral`
/// endpoint: a `kind` filter on that listing, plus `markNotificationAsReadNeutral`/
/// `markAllNotificationsAsReadNeutral`/`unreadCountsNeutral`.
final class InboxNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private func capturedJSONBody(_ transport: BodyCapturingStubTransport) async throws -> [String: Any] {
        let capturedData = await transport.capturedRequestBodyData
        let data = try XCTUnwrap(capturedData)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: listNotificationsNeutral(kind:) -- v3 fan-out narrowing

    /// `kind: .reply` on v3 must call *only* `getReplies` -- not `getPersonMentions` or
    /// `getPrivateMessages`. `PathRoutingStubTransport` only has a fixture for the replies path,
    /// so it fails the test if either of the other two is called.
    func testListNotificationsNeutralV3ReplyKindCallsOnlyGetReplies() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/v3/user/replies": fixtureData("getRepliesResponseV3"),
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.listNotificationsNeutral(kind: .reply)

        XCTAssertFalse(page.items.isEmpty)
        XCTAssertTrue(page.items.allSatisfy { $0.notification.kind == .reply })
    }

    /// `kind: .mention` on v3 must call *only* `getPersonMentions`.
    func testListNotificationsNeutralV3MentionKindCallsOnlyGetPersonMentions() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/v3/user/mention": fixtureData("getPersonMentionsResponseV3"),
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.listNotificationsNeutral(kind: .mention)

        XCTAssertFalse(page.items.isEmpty)
        XCTAssertTrue(page.items.allSatisfy { $0.notification.kind == .mention })
    }

    /// `kind: .privateMessage` on v3 must call *only* `getPrivateMessages`.
    func testListNotificationsNeutralV3PrivateMessageKindCallsOnlyGetPrivateMessages() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/v3/private_message/list": fixtureData("getPrivateMessagesResponseV3"),
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.listNotificationsNeutral(kind: .privateMessage)

        XCTAssertFalse(page.items.isEmpty)
        XCTAssertTrue(page.items.allSatisfy { $0.notification.kind == .privateMessage })
    }

    /// `kind: .subscribed`/`.modAction` have no v3 source at all -- neither calls any endpoint,
    /// and both return an empty page rather than throwing. An empty `responseBodiesByPath` fails
    /// the test if any request is made.
    func testListNotificationsNeutralV3SubscribedAndModActionKindsCallNothingAndReturnEmpty() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [:])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let subscribedPage = try await api.listNotificationsNeutral(kind: .subscribed)
        XCTAssertTrue(subscribedPage.items.isEmpty)

        let modActionPage = try await api.listNotificationsNeutral(kind: .modAction)
        XCTAssertTrue(modActionPage.items.isEmpty)
    }

    // MARK: listNotificationsNeutral(kind:) -- v4 query filter

    /// `kind: .reply` on v4 must send `type_=reply` in the request's query string.
    func testListNotificationsNeutralV4ReplyKindSendsTypeFilterInQuery() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("listNotificationsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        _ = try await api.listNotificationsNeutral(kind: .reply)

        let capturedPath = await transport.capturedPath
        let path = try XCTUnwrap(capturedPath)
        XCTAssertTrue(path.contains("type_=reply"), "Expected \"type_=reply\" in query, got: \(path)")
    }

    /// `kind: nil` (the default) must not constrain the request -- no `type_` in the query.
    func testListNotificationsNeutralV4NilKindOmitsTypeFilter() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("listNotificationsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        _ = try await api.listNotificationsNeutral()

        let capturedPath = await transport.capturedPath
        let path = try XCTUnwrap(capturedPath)
        XCTAssertFalse(path.contains("type_="), "Expected no \"type_\" in query, got: \(path)")
    }

    // MARK: unreadCountsNeutral

    func testUnreadCountsNeutralV3SumsThreePerKindCounts() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getUnreadCountResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let counts = try await api.unreadCountsNeutral()

        XCTAssertEqual(counts.total, 6)
        XCTAssertEqual(counts.replies, 3)
        XCTAssertEqual(counts.mentions, 2)
        XCTAssertEqual(counts.privateMessages, 1)
    }

    func testUnreadCountsNeutralV4UsesNotificationCountAsTotal() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("unreadCountsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let counts = try await api.unreadCountsNeutral()

        XCTAssertEqual(counts.total, 7)
        XCTAssertNil(counts.replies)
        XCTAssertNil(counts.mentions)
        XCTAssertNil(counts.privateMessages)
    }

    // MARK: markNotificationAsReadNeutral

    func testMarkNotificationAsReadNeutralV4SendsNotificationIdAndRead() async throws {
        let transport = try BodyCapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.markNotificationAsReadNeutral(id: 101, read: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["notification_id"] as? Int, 101)
        XCTAssertEqual(body["read"] as? Bool, true)
    }

    /// v3 has no unified notification id, so this is a documented no-op -- it must not make any
    /// request. An empty `responseBodiesByPath` fails the test if it does.
    func testMarkNotificationAsReadNeutralV3IsNoOpAndDoesNotThrow() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [:])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.markNotificationAsReadNeutral(id: 101, read: true)
    }

    // MARK: markAllNotificationsAsReadNeutral

    func testMarkAllNotificationsAsReadNeutralV3DoesNotThrow() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("getRepliesResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.markAllNotificationsAsReadNeutral()
    }

    func testMarkAllNotificationsAsReadNeutralV4DoesNotThrow() async throws {
        let transport = try PathCapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.markAllNotificationsAsReadNeutral()
    }
}
