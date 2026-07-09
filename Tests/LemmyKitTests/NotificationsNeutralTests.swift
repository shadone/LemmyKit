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
/// sent, so `listNotificationsNeutral`'s v4 path can be exercised end-to-end without hitting the
/// network -- the same stub `GetPostNeutralTests.swift`/`GetListNeutralTests.swift` use.
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

/// A `ClientTransport` that routes by request path, unlike `StubTransport` above -- needed
/// because `listNotificationsNeutral`'s v3 path fans out to three different v3 endpoints
/// (`getReplies`/`getPersonMentions`/`getPrivateMessages`), each of which must return its own
/// fixture body.
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

/// Proves the hardest v3 emulation in the dual-version initiative: `listNotificationsNeutral`
/// dispatches, on v4, to a single `ListNotifications` call mapped near-directly to the neutral
/// `NotificationView`'s four-way `anyOf` payload; on v3 (no unified inbox endpoint at all), it
/// fans `getReplies`/`getPersonMentions`/`getPrivateMessages` out concurrently and k-way merges
/// them by `publishedAt` descending into one timeline.
final class NotificationsNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: v4 -- mixed-kind fixture

    func testListNotificationsNeutralV4MapsMixedKindItems() async throws {
        let transport = try StubTransport(responseBody: fixtureData("listNotificationsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.listNotificationsNeutral()

        XCTAssertEqual(page.items.count, 2)

        let replyItem = page.items[0]
        XCTAssertEqual(replyItem.notification.id, 101)
        XCTAssertEqual(replyItem.notification.kind, .reply)
        XCTAssertFalse(replyItem.notification.isRead)
        guard case let .comment(commentView) = replyItem.data else {
            return XCTFail("Expected .comment, got \(replyItem.data)")
        }
        XCTAssertEqual(commentView.comment.id, 501)
        XCTAssertEqual(commentView.creator.name, "seed_mod1")

        let privateMessageItem = page.items[1]
        XCTAssertEqual(privateMessageItem.notification.id, 102)
        XCTAssertEqual(privateMessageItem.notification.kind, .privateMessage)
        XCTAssertTrue(privateMessageItem.notification.isRead)
        guard case let .privateMessage(privateMessageView) = privateMessageItem.data else {
            return XCTFail("Expected .privateMessage, got \(privateMessageItem.data)")
        }
        XCTAssertEqual(privateMessageView.privateMessage.id, 3)
        XCTAssertEqual(privateMessageView.privateMessage.content, "Hey there!")
        XCTAssertEqual(privateMessageView.recipient.name, "seed_reader")
    }

    // MARK: v3 -- three-endpoint fan-out and merge

    func testListNotificationsNeutralV3FansOutAndMergesByDateDescending() async throws {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/v3/user/replies": fixtureData("getRepliesResponseV3"),
            "/api/v3/user/mention": fixtureData("getPersonMentionsResponseV3"),
            "/api/v3/private_message/list": fixtureData("getPrivateMessagesResponseV3"),
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.listNotificationsNeutral()

        // Fixture dates are deliberately interleaved: mention=15:00, reply=12:00, PM=09:00 --
        // this must come back sorted by publishedAt descending, not in fan-out/source order.
        XCTAssertEqual(page.items.map(\.notification.kind), [.mention, .reply, .privateMessage])
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)

        let mentionItem = page.items[0]
        XCTAssertFalse(mentionItem.notification.isRead)
        guard case let .comment(mentionComment) = mentionItem.data else {
            return XCTFail("Expected .comment, got \(mentionItem.data)")
        }
        XCTAssertEqual(mentionComment.comment.id, 502)

        let replyItem = page.items[1]
        XCTAssertFalse(replyItem.notification.isRead)
        guard case let .comment(replyComment) = replyItem.data else {
            return XCTFail("Expected .comment, got \(replyItem.data)")
        }
        XCTAssertEqual(replyComment.comment.id, 501)

        let privateMessageItem = page.items[2]
        XCTAssertTrue(privateMessageItem.notification.isRead)
        guard case let .privateMessage(privateMessageView) = privateMessageItem.data else {
            return XCTFail("Expected .privateMessage, got \(privateMessageItem.data)")
        }
        XCTAssertEqual(privateMessageView.privateMessage.content, "Hey there!")

        // v3 has no unified notification id -- every merged item's id is nil (see
        // `Notification.id`'s doc).
        XCTAssertTrue(page.items.allSatisfy { $0.notification.id == nil })
    }
}
