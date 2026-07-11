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

/// A `ClientTransport` that returns a canned response for every request and captures the outgoing
/// request's path (which includes the query string for a GET) -- so the paginated private-message
/// listing's *request* shape (page/limit on v3, `type_`/`unread_only` on v4) can be asserted, not
/// just the returned neutral items. Same shape as `AccountFeedsNeutralTests.swift`'s transport.
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

/// Proves `getPrivateMessagesNeutral` end-to-end: v3 synthesizes a page-number cursor over the
/// legacy page/limit `getPrivateMessages` (full page → next cursor, short page → nil), and v4
/// filters the unified `ListNotifications` to private messages and forwards the native cursor. Both
/// legs pair each ``PrivateMessageView`` with its read state (`private_message.read` on v3,
/// `notification.read` on v4), which a bare `Page<PrivateMessageView>` would drop.
final class PrivateMessagesNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// The path component only, stripped of its query string.
    private func pathWithoutQuery(_ path: String?) -> String? {
        path?.split(separator: "?", maxSplits: 1).first.map(String.init)
    }

    /// Builds a v3 `PrivateMessagesResponse` body with `count` identical messages by repeating the
    /// single-entry fixture's element, so the synthesized-cursor logic can be exercised at an exact
    /// page boundary without hand-writing 50 entries.
    private func privateMessagesResponseV3(count: Int) throws -> Data {
        let base = try fixtureData("getPrivateMessagesResponseV3")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: base) as? [String: Any])
        let messages = try XCTUnwrap(object["private_messages"] as? [Any])
        let one = try XCTUnwrap(messages.first)
        return try JSONSerialization.data(
            withJSONObject: ["private_messages": Array(repeating: one, count: count)]
        )
    }

    // MARK: v3

    /// A full page (count == the fixed page size of 50) synthesizes a `nextPage` cursor for the
    /// next page number, and the outgoing request carried page=1/limit=50. `prevPage` is always nil
    /// on v3.
    func testGetPrivateMessagesNeutralV3FullPageSynthesizesNextCursor() async throws {
        let transport = try CapturingStubTransport(responseBody: privateMessagesResponseV3(count: 50))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getPrivateMessagesNeutral()

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v3/private_message/list")
        XCTAssertTrue(path.contains("page=1"), "expected page=1 in path, got: \(path)")
        XCTAssertTrue(path.contains("limit=50"), "expected limit=50 in path, got: \(path)")

        XCTAssertEqual(page.items.count, 50)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "2"))
        XCTAssertNil(page.prevPage)
    }

    /// A short page (fewer than the page size) ends the listing: `nextPage` is nil, and `isRead`
    /// reflects the v3 `private_message.read` field (the single-entry fixture has `read: true`).
    func testGetPrivateMessagesNeutralV3ShortPageHasNoNextCursorAndReflectsRead() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPrivateMessagesResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.getPrivateMessagesNeutral()

        XCTAssertEqual(page.items.count, 1)
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)

        let item = try XCTUnwrap(page.items.first)
        XCTAssertTrue(item.isRead)
        XCTAssertEqual(item.view.privateMessage.id, 3)
        XCTAssertEqual(item.view.privateMessage.content, "Hey there!")
        XCTAssertEqual(item.view.creator.name, "seed_mod1")
        XCTAssertEqual(item.view.recipient.name, "seed_reader")
    }

    /// A page-2 cursor decodes back to page=2 in the outgoing request.
    func testGetPrivateMessagesNeutralV3Page2CursorDecodesToPage2() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPrivateMessagesResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.getPrivateMessagesNeutral(pageCursor: Cursor(rawValue: "2"))

        let path = await transport.capturedPath ?? ""
        XCTAssertTrue(path.contains("page=2"), "expected page=2 in path, got: \(path)")
        XCTAssertTrue(path.contains("limit=50"), "expected limit=50 in path, got: \(path)")
    }

    // MARK: v4

    /// v4 filters the unified inbox to private messages (`type_=private_message`), forwards
    /// `unread_only`, forwards the server's native `next_page` cursor unchanged, and sources `isRead`
    /// from `notification.read` (the fixture's PM is `read: false`).
    func testGetPrivateMessagesNeutralV4ForwardsNativeCursorAndFilters() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("getPrivateMessagesResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.getPrivateMessagesNeutral(unreadOnly: true)

        let path = await transport.capturedPath ?? ""
        XCTAssertEqual(pathWithoutQuery(path), "/api/v4/account/notification/list")
        XCTAssertTrue(path.contains("type_=private_message"), "expected type_ filter in path, got: \(path)")
        XCTAssertTrue(path.contains("unread_only=true"), "expected unread_only in path, got: \(path)")

        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "PcPM2"))
        XCTAssertNil(page.prevPage)

        let item = try XCTUnwrap(page.items.first)
        XCTAssertFalse(item.isRead)
        XCTAssertEqual(item.view.privateMessage.id, 3)
        XCTAssertEqual(item.view.privateMessage.content, "Hey there!")
        XCTAssertEqual(item.view.recipient.name, "seed_reader")
    }
}
