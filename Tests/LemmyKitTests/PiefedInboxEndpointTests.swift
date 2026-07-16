//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing
@testable import LemmyKit

/// A `ClientTransport` that routes by request METHOD + path (falling back from the full path incl.
/// query to the bare path, same fallback `PiefedNeutralEndpointTests.swift`'s `PathRoutingStubTransport`
/// uses) and captures the outgoing request body per matched route -- the union of
/// `PiefedWriteEndpointTests.swift`'s `MethodPathRoutingStubTransport` (method+body capture) and
/// `PiefedNeutralEndpointTests.swift`'s query-aware path matching, needed here because this suite
/// exercises both `GET` routes with query strings (`getReplies`/`getMentions`/`getPrivateMessages`)
/// and `POST` routes with bodies (`markCommentReplyAsRead`/`markAllAsRead`/`createPrivateMessage`).
private actor MethodPathRoutingStubTransport: ClientTransport {
    private let responseBodiesByRoute: [String: Data]
    private(set) var capturedBodyDataByRoute: [String: Data] = [:]

    init(responseBodiesByRoute: [String: Data]) {
        self.responseBodiesByRoute = responseBodiesByRoute
    }

    private static func routeKey(_ method: HTTPRequest.Method, _ path: String) -> String {
        "\(method.rawValue) \(path)"
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let fullPath = request.path ?? ""
        let pathWithoutQuery = fullPath.split(separator: "?", maxSplits: 1).first.map(String.init) ?? fullPath

        let fullRoute = Self.routeKey(request.method, fullPath)
        let bareRoute = Self.routeKey(request.method, pathWithoutQuery)

        let matched: (route: String, body: Data)? = responseBodiesByRoute[fullRoute].map { (fullRoute, $0) }
            ?? responseBodiesByRoute[bareRoute].map { (bareRoute, $0) }

        guard let matched else {
            Issue.record("Unexpected request: \(fullRoute)")
            return (HTTPResponse(status: .init(code: 404)), HTTPBody("{}".data(using: .utf8)!))
        }

        if let body {
            capturedBodyDataByRoute[matched.route] = try await Data(collecting: body, upTo: 10 * 1024 * 1024)
        }

        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(matched.body))
    }

    func capturedBodyData(_ method: HTTPRequest.Method, _ path: String) -> Data? {
        capturedBodyDataByRoute[Self.routeKey(method, path)]
    }
}

/// A `ClientTransport` that always fails if invoked -- proves that the `kind: nil` (and
/// PieFed-unsupported-kind) `unsupportedByDialect` throw happens at the facade's dispatch, before
/// any request is built or sent. Matches `PiefedDialectTests.swift`'s `NeverCalledTransport`.
private struct NeverCalledTransport: ClientTransport {
    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        Issue.record("transport should never be called for an endpoint gated unsupportedByDialect")
        throw URLError(.badURL)
    }
}

/// End-to-end coverage for the inbox + private-message endpoints' `.piefed` dispatch (Phase 2,
/// Task 6): `LemmyApi`'s `apiVersion == .piefed` now calls `PiefedClient`'s inbox/private-message
/// surface and maps the response through the existing `neutralX(fromPiefed:)` adapters, replacing
/// the `unsupportedByDialect` throw. Each test asserts the outgoing route+method(+body) and the
/// mapped neutral DTO, pinned against the real captured `piefed-*.json` fixtures -- the same
/// discipline `PiefedNeutralEndpointTests.swift`/`PiefedWriteEndpointTests.swift` established.
struct PiefedInboxEndpointTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// Wraps `piefed-replies_item.json` (a single synthetic `PiefedReplyItem`) in the
    /// `PiefedRepliesResponse` envelope both `getReplies` and `getMentions` share, with the given
    /// `next_page` cursor -- there is no fixture for a NON-empty replies/mentions response, so this
    /// composes one at test time from the two building-block fixtures the task specifies.
    private func repliesResponse(nextPage: String?) throws -> Data {
        let item = try JSONSerialization.jsonObject(with: fixture("piefed-replies_item"))
        let wrapper: [String: Any] = [
            "replies": [item],
            "next_page": nextPage ?? NSNull(),
        ]
        return try JSONSerialization.data(withJSONObject: wrapper)
    }

    /// Wraps `piefed-replies_item.json` in the `PiefedCommentReplyResponse` envelope
    /// `markCommentReplyAsRead` returns (`{"comment_reply_view": ...}`).
    private func commentReplyResponse() throws -> Data {
        let item = try JSONSerialization.jsonObject(with: fixture("piefed-replies_item"))
        let wrapper: [String: Any] = ["comment_reply_view": item]
        return try JSONSerialization.data(withJSONObject: wrapper)
    }

    /// Wraps `count` copies of `piefed-pm_view.json` in the `PiefedPrivateMessageListResponse`
    /// envelope (`{"private_messages": [...]}`) -- `count` copies (rather than one) let a test
    /// trigger the piefed arm's full-page `nextPage` synthesis.
    private func privateMessagesResponse(count: Int) throws -> Data {
        let view = try JSONSerialization.jsonObject(with: fixture("piefed-pm_view"))
        let wrapper: [String: Any] = ["private_messages": Array(repeating: view, count: count)]
        return try JSONSerialization.data(withJSONObject: wrapper)
    }

    /// Wraps `piefed-pm_view.json` in the `PiefedPrivateMessageResponse` envelope
    /// `createPrivateMessage` returns (`{"private_message_view": ...}`).
    private func privateMessageViewResponse() throws -> Data {
        let view = try JSONSerialization.jsonObject(with: fixture("piefed-pm_view"))
        let wrapper: [String: Any] = ["private_message_view": view]
        return try JSONSerialization.data(withJSONObject: wrapper)
    }

    private func capturedJSONBody(
        _ transport: MethodPathRoutingStubTransport,
        _ method: HTTPRequest.Method,
        _ path: String
    ) async throws -> [String: Any] {
        let capturedData = await transport.capturedBodyData(method, path)
        let data = try #require(capturedData)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeApi(_ transport: some ClientTransport) -> LemmyApi {
        LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: LemmyCredential(jwt: "t"),
            transport: transport,
            apiVersion: .piefed
        )
    }

    // MARK: - listNotificationsNeutral(kind: .reply)

    @Test
    func listNotificationsNeutralReplyKindCallsGetRepliesAndMapsFixtureItemFaithfully() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/user/replies?unread_only=true": repliesResponse(nextPage: "2"),
        ])
        let api = makeApi(transport)

        let page = try await api.listNotificationsNeutral(unreadOnly: true, pageCursor: nil, kind: .reply)

        #expect(page.items.count == 1)
        let entry = try #require(page.items.first)
        #expect(entry.notification.kind == .reply)
        // piefed-replies_item.json's comment_reply.id is 1, .read is false.
        #expect(entry.notification.id == 1)
        #expect(entry.notification.isRead == false)
        guard case let .comment(commentView) = entry.data else {
            Issue.record("expected .comment notification data")
            return
        }
        #expect(commentView.comment.content == "Spud fixture capture - will be deleted")

        #expect(page.nextPage == Cursor(rawValue: "2"))
        #expect(page.prevPage == nil)
    }

    // MARK: - listNotificationsNeutral(kind: .mention)

    @Test
    func listNotificationsNeutralMentionKindCallsGetMentionsAndTagsKindMention() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/user/mentions?unread_only=false&page=3": repliesResponse(nextPage: nil),
        ])
        let api = makeApi(transport)

        let page = try await api.listNotificationsNeutral(
            unreadOnly: false,
            pageCursor: Cursor(rawValue: "3"),
            kind: .mention
        )

        #expect(page.items.count == 1)
        // Same underlying PiefedReplyItem shape as .reply -- only `kind` differs, since PieFed's
        // wire item carries no signal distinguishing the two (see
        // `neutralNotificationView(fromPiefedReply:kind:)`'s doc).
        #expect(page.items.first?.notification.kind == .mention)
        #expect(page.nextPage == nil)
    }

    @Test
    func listNotificationsNeutralEmptyFixtureGivesEmptyPage() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/user/replies": fixture("piefed-replies"),
        ])
        let api = makeApi(transport)

        let page = try await api.listNotificationsNeutral(unreadOnly: false, pageCursor: nil, kind: .reply)

        #expect(page.items.isEmpty)
        #expect(page.nextPage == nil)
        #expect(page.prevPage == nil)
    }

    // MARK: - listNotificationsNeutral(kind: nil / PieFed-unsupported kinds)

    @Test
    func listNotificationsNeutralNilKindThrowsUnsupportedByDialectWithoutCallingTransport() async throws {
        let api = makeApi(NeverCalledTransport())

        do {
            _ = try await api.listNotificationsNeutral(unreadOnly: false, pageCursor: nil, kind: nil)
            Issue.record("expected listNotificationsNeutral to throw for kind: nil on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "listNotifications(kind:nil)")
        }
    }

    @Test(arguments: [NotificationKind.subscribed, .modAction, .privateMessage])
    func listNotificationsNeutralUnsupportedKindsThrowUnsupportedByDialectWithoutCallingTransport(
        kind: NotificationKind
    ) async throws {
        let api = makeApi(NeverCalledTransport())

        do {
            _ = try await api.listNotificationsNeutral(unreadOnly: false, pageCursor: nil, kind: kind)
            Issue.record("expected listNotificationsNeutral to throw for kind: \(kind) on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation.hasPrefix("listNotifications(kind:"))
        }
    }

    // MARK: - markNotificationAsReadNeutral

    @Test
    func markNotificationAsReadNeutralPostsCommentReplyIdAndRead() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/comment/mark_as_read": commentReplyResponse(),
        ])
        let api = makeApi(transport)

        // The bare neutral `id` carries no `kind` -- this exercises it against the SAME id space
        // both a reply- and a mention-sourced notification share on PieFed (see the mark-read
        // resolution documented on `markNotificationAsReadNeutralPiefed`).
        try await api.markNotificationAsReadNeutral(id: 1, read: true)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/comment/mark_as_read")
        #expect(body["comment_reply_id"] as? Int == 1)
        #expect(body["read"] as? Bool == true)
    }

    // MARK: - markAllNotificationsAsReadNeutral

    @Test
    func markAllNotificationsAsReadNeutralPostsToMarkAllAsRead() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/user/mark_all_as_read": fixture("piefed-replies"),
        ])
        let api = makeApi(transport)

        try await api.markAllNotificationsAsReadNeutral()

        // `markAllAsRead()`'s wire body is `PiefedEmptyRequestBody` -- an empty JSON object, no
        // fields -- confirmed live to take no request body (see that method's doc).
        let body = try await capturedJSONBody(transport, .post, "/api/alpha/user/mark_all_as_read")
        #expect(body.isEmpty)
    }

    // MARK: - getPrivateMessagesNeutral

    @Test
    func getPrivateMessagesNeutralEmptyFixtureGivesEmptyPage() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/private_message/list": fixture("piefed-pm_list"),
        ])
        let api = makeApi(transport)

        let page = try await api.getPrivateMessagesNeutral(unreadOnly: false, pageCursor: nil)

        #expect(page.items.isEmpty)
        #expect(page.nextPage == nil)
        #expect(page.prevPage == nil)
    }

    @Test
    func getPrivateMessagesNeutralMapsItemsAndSynthesizesNextPageWhenPageIsFull() async throws {
        // 20 copies matches `privateMessagesNeutralPiefedPageSize` -- a "full" page, so `nextPage`
        // must be synthesized (PieFed's private-message list carries no native cursor at all, see
        // `getPrivateMessagesNeutralPiefed`'s doc).
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/private_message/list?unread_only=true&page=1&limit=20":
                privateMessagesResponse(count: 20),
        ])
        let api = makeApi(transport)

        let page = try await api.getPrivateMessagesNeutral(unreadOnly: true, pageCursor: nil)

        #expect(page.items.count == 20)
        let firstItem = try #require(page.items.first)
        // piefed-pm_view.json's private_message.read is false.
        #expect(firstItem.isRead == false)
        #expect(firstItem.view.privateMessage.content == "Synthetic DM body for fixture decoding")
        #expect(page.nextPage == Cursor(rawValue: "2"))
        #expect(page.prevPage == nil)
    }

    @Test
    func getPrivateMessagesNeutralShortPageMeansNoNextPage() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/private_message/list?unread_only=false&page=1&limit=20":
                privateMessagesResponse(count: 3),
        ])
        let api = makeApi(transport)

        let page = try await api.getPrivateMessagesNeutral(unreadOnly: false, pageCursor: nil)

        #expect(page.items.count == 3)
        #expect(page.nextPage == nil)
    }

    @Test
    func getPrivateMessagesNeutralResumesFromOpaqueCursor() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "GET /api/alpha/private_message/list?unread_only=false&page=3&limit=20":
                privateMessagesResponse(count: 1),
        ])
        let api = makeApi(transport)

        let page = try await api.getPrivateMessagesNeutral(unreadOnly: false, pageCursor: Cursor(rawValue: "3"))

        #expect(page.items.count == 1)
    }

    // MARK: - createPrivateMessageNeutral

    @Test
    func createPrivateMessageNeutralPostsContentAndRecipientAndMapsFixture() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/private_message": privateMessageViewResponse(),
        ])
        let api = makeApi(transport)

        let view = try await api.createPrivateMessageNeutral(content: "hello there", recipientId: 10)

        #expect(view.privateMessage.content == "Synthetic DM body for fixture decoding")
        #expect(view.privateMessage.apId == "https://piefed1.lemmy.ddenis.info/private_message/1")

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/private_message")
        #expect(body["content"] as? String == "hello there")
        #expect(body["recipient_id"] as? Int == 10)
    }
}
