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

/// A `ClientTransport` that routes by request METHOD + path, returning a canned fixture body per
/// route -- extends `PiefedNeutralEndpointTests.swift`'s `PathRoutingStubTransport` pattern (which
/// only matched on path, sufficient for Phase 1's read-only `GET` surface) with the HTTP method,
/// since Phase 2's write surface reuses the same paths across different methods (e.g. `POST
/// /api/alpha/post` creates, `PUT /api/alpha/post` edits) and a wrong-method dispatch must fail
/// the test rather than silently matching. Also captures the outgoing request body per route, so
/// tests can assert the write direction (e.g. `score`, `save`, omitted-when-nil edit fields), not
/// just the returned neutral view -- mirrors `MutationNeutralTests.swift`'s `CapturingStubTransport`
/// and `PiefedWriteClientTests.swift`'s `RecordingBodyStubTransport`.
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
        let route = Self.routeKey(request.method, pathWithoutQuery)

        guard let responseBody = responseBodiesByRoute[route] else {
            Issue.record("Unexpected request: \(route)")
            return (HTTPResponse(status: .init(code: 404)), HTTPBody("{}".data(using: .utf8)!))
        }

        if let body {
            capturedBodyDataByRoute[route] = try await Data(collecting: body, upTo: 10 * 1024 * 1024)
        }

        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }

    /// The raw JSON body bytes captured for the given method + path, or nil if that route was
    /// never hit. Returns `Data` (not a decoded `[String: Any]`) because a loose JSON dictionary
    /// isn't `Sendable` and can't cross this actor's isolation boundary -- callers decode it with
    /// `PiefedWriteEndpointTests.capturedJSONBody(_:_:_:)` on the nonisolated side instead.
    func capturedBodyData(_ method: HTTPRequest.Method, _ path: String) -> Data? {
        capturedBodyDataByRoute[Self.routeKey(method, path)]
    }
}

/// End-to-end coverage for the fourteen write/auth endpoints' `.piefed` dispatch (Phase 2, Task 4):
/// `LemmyApi`'s `apiVersion == .piefed` now calls `PiefedClient`'s write surface and maps the
/// response through the `neutralX(fromPiefed:)` adapters, replacing the `unsupportedByDialect`
/// throw `PiefedDialectTests.swift` proved before this task (that file now samples endpoints that
/// remain gated instead). Each test asserts BOTH the outgoing route+method+body and the mapped
/// neutral DTO, pinned against the real captured `piefed-*.json` fixtures -- the same discipline
/// `PiefedNeutralEndpointTests.swift` established for the read endpoints.
struct PiefedWriteEndpointTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// Decodes a captured request body as a loose JSON dictionary, so individual fields can be
    /// asserted without depending on the (internal) generated request type.
    private func capturedJSONBody(
        _ transport: MethodPathRoutingStubTransport,
        _ method: HTTPRequest.Method,
        _ path: String
    ) async throws -> [String: Any] {
        let capturedData = await transport.capturedBodyData(method, path)
        let data = try #require(capturedData)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeApi(
        _ transport: MethodPathRoutingStubTransport
    ) -> LemmyApi {
        LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: LemmyCredential(jwt: "t"),
            transport: transport,
            apiVersion: .piefed
        )
    }

    // MARK: - loginNeutral

    @Test
    func loginNeutralSendsUsernameIgnoresTotpAndReturnsJWT() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/user/login": fixture("piefed-login"),
        ])
        let api = makeApi(transport)

        let jwt = try await api.loginNeutral(usernameOrEmail: "alice", password: "hunter2", totp: "123456")
        #expect(jwt == "fixture.jwt.value")

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/user/login")
        #expect(body["username"] as? String == "alice")
        #expect(body["password"] as? String == "hunter2")
        // PieFed's login route has no wire field for a TOTP code at all -- `totp` is silently
        // ignored, not sent under any key.
        #expect(body["totp"] == nil)
        #expect(body["totp_2fa_token"] == nil)
    }

    // MARK: - votePostNeutral

    @Test
    func votePostNeutralConvertsDirectionToSignedScoreAndReturnsNeutralPostView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/post/like": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        let postView = try await api.votePostNeutral(id: 13, direction: .up)
        #expect(postView.post.id == 13)
        // piefed-post_response.json's my_vote is 1 -- confirms the response mapping, not just the
        // request encoding.
        #expect(postView.postActions?.voteIsUpvote == true)

        var body = try await capturedJSONBody(transport, .post, "/api/alpha/post/like")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["score"] as? Int == 1)

        _ = try await api.votePostNeutral(id: 13, direction: .down)
        body = try await capturedJSONBody(transport, .post, "/api/alpha/post/like")
        #expect(body["score"] as? Int == -1)

        _ = try await api.votePostNeutral(id: 13, direction: .none)
        body = try await capturedJSONBody(transport, .post, "/api/alpha/post/like")
        #expect(body["score"] as? Int == 0)
    }

    // MARK: - voteCommentNeutral

    @Test
    func voteCommentNeutralConvertsDirectionToSignedScoreAndReturnsNeutralCommentView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/comment/like": fixture("piefed-comment_response"),
        ])
        let api = makeApi(transport)

        let commentView = try await api.voteCommentNeutral(id: 7, direction: .up)
        #expect(commentView.comment.id == 7)
        // piefed-comment_response.json's my_vote is 1.
        #expect(commentView.commentActions?.voteIsUpvote == true)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/comment/like")
        #expect(body["comment_id"] as? Int == 7)
        #expect(body["score"] as? Int == 1)
    }

    // MARK: - savePostNeutral

    @Test
    func savePostNeutralSendsSaveAndReturnsNeutralPostView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "PUT /api/alpha/post/save": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        let postView = try await api.savePostNeutral(id: 13, saved: true)
        #expect(postView.post.id == 13)

        let body = try await capturedJSONBody(transport, .put, "/api/alpha/post/save")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["save"] as? Bool == true)
    }

    // MARK: - saveCommentNeutral

    @Test
    func saveCommentNeutralSendsSaveAndReturnsNeutralCommentView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "PUT /api/alpha/comment/save": fixture("piefed-comment_response"),
        ])
        let api = makeApi(transport)

        let commentView = try await api.saveCommentNeutral(id: 7, saved: true)
        #expect(commentView.comment.id == 7)

        let body = try await capturedJSONBody(transport, .put, "/api/alpha/comment/save")
        #expect(body["comment_id"] as? Int == 7)
        #expect(body["save"] as? Bool == true)
    }

    // MARK: - followCommunityNeutral

    @Test
    func followCommunityNeutralSendsFollowAndReturnsAcceptedFollowState() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/community/follow": fixture("piefed-community_follow"),
        ])
        let api = makeApi(transport)

        let communityView = try await api.followCommunityNeutral(id: 1, follow: true)
        // piefed-community_follow.json's subscribed is "Subscribed".
        #expect(communityView.followState == .accepted)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/community/follow")
        #expect(body["community_id"] as? Int == 1)
        #expect(body["follow"] as? Bool == true)
    }

    // MARK: - markPostAsReadNeutral

    @Test
    func markPostAsReadNeutralSendsReadAndDiscardsSuccessPayload() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/post/mark_as_read": fixture("piefed-success"),
        ])
        let api = makeApi(transport)

        try await api.markPostAsReadNeutral(id: 13, read: true)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/post/mark_as_read")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["read"] as? Bool == true)
    }

    // MARK: - hidePostNeutral

    @Test
    func hidePostNeutralSendsHiddenFieldAndSucceeds() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/post/hide": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        try await api.hidePostNeutral(id: 13, hidden: true)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/post/hide")
        #expect(body["post_id"] as? Int == 13)
        // The wire field is `hidden`, not `hide` -- confirmed against the Task-2 client body.
        #expect(body["hidden"] as? Bool == true)
        #expect(body["hide"] == nil)
    }

    // MARK: - deletePostNeutral

    @Test
    func deletePostNeutralSendsDeletedAndReturnsNeutralPostView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/post/delete": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        let postView = try await api.deletePostNeutral(id: 13, deleted: true)
        #expect(postView.post.id == 13)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/post/delete")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["deleted"] as? Bool == true)
    }

    // MARK: - deleteCommentNeutral

    @Test
    func deleteCommentNeutralSendsDeletedAndReturnsNeutralCommentView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/comment/delete": fixture("piefed-comment_response"),
        ])
        let api = makeApi(transport)

        let commentView = try await api.deleteCommentNeutral(id: 7, deleted: true)
        #expect(commentView.comment.id == 7)

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/comment/delete")
        #expect(body["comment_id"] as? Int == 7)
        #expect(body["deleted"] as? Bool == true)
    }

    // MARK: - createCommentNeutral

    @Test
    func createCommentNeutralSendsBodyFieldAndReturnsNeutralCommentView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/comment": fixture("piefed-comment_response"),
        ])
        let api = makeApi(transport)

        let commentView = try await api.createCommentNeutral(
            content: "Spud fixture capture - will be deleted",
            postId: 13,
            parentId: nil,
            languageId: 2
        )
        #expect(commentView.comment.content == "Spud fixture capture - will be deleted")

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/comment")
        // PieFed's comment body wire field is `body`, not Lemmy's `content`.
        #expect(body["body"] as? String == "Spud fixture capture - will be deleted")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["language_id"] as? Int == 2)
        #expect(body["parent_id"] == nil)
    }

    // MARK: - editCommentNeutral

    @Test
    func editCommentNeutralSendsBodyFieldAndReturnsNeutralCommentView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "PUT /api/alpha/comment": fixture("piefed-comment_response"),
        ])
        let api = makeApi(transport)

        let commentView = try await api.editCommentNeutral(id: 7, content: "edited")
        #expect(commentView.comment.id == 7)

        let body = try await capturedJSONBody(transport, .put, "/api/alpha/comment")
        #expect(body["body"] as? String == "edited")
        #expect(body["comment_id"] as? Int == 7)
    }

    // MARK: - createPostNeutral

    @Test
    func createPostNeutralSendsTitleFieldAndReturnsNeutralPostView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "POST /api/alpha/post": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        let postView = try await api.createPostNeutral(
            name: "Pushfix verification post",
            communityId: 1,
            url: nil,
            body: "Created after re-follow to confirm push federation works post-fix.",
            nsfw: false,
            languageId: 2
        )
        #expect(postView.post.name == "Pushfix verification post")

        let body = try await capturedJSONBody(transport, .post, "/api/alpha/post")
        // PieFed's post title wire field is `title`, not Lemmy's `name`.
        #expect(body["title"] as? String == "Pushfix verification post")
        #expect(body["community_id"] as? Int == 1)
        #expect(body["language_id"] as? Int == 2)
        #expect(body["url"] == nil)
    }

    // MARK: - editPostNeutral

    @Test
    func editPostNeutralSendsOnlyNonNilFieldsAndReturnsNeutralPostView() async throws {
        let transport = try MethodPathRoutingStubTransport(responseBodiesByRoute: [
            "PUT /api/alpha/post": fixture("piefed-post_response"),
        ])
        let api = makeApi(transport)

        let postView = try await api.editPostNeutral(id: 13, name: "New title", url: nil, body: nil, nsfw: nil)
        #expect(postView.post.id == 13)

        let body = try await capturedJSONBody(transport, .put, "/api/alpha/post")
        #expect(body["post_id"] as? Int == 13)
        #expect(body["title"] as? String == "New title")
        // Every other field was passed nil -- the request struct's synthesized `Encodable`
        // omits nil optionals entirely (not JSON `null`), so PieFed leaves those fields unchanged.
        #expect(body["url"] == nil)
        #expect(body["body"] == nil)
        #expect(body["nsfw"] == nil)
    }
}
