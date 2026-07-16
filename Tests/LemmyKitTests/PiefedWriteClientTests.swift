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

/// A `ClientTransport` that returns a canned response for every request and records the exact
/// `HTTPRequest` it was sent -- method, path, header fields, AND the raw request body bytes -- so
/// tests can assert on what `PiefedClient`'s write engine (`send`) builds without hitting the
/// network. A sibling of `PiefedClientTests.swift`'s `RecordingStubTransport` (which only captures
/// path + headers, since Phase 1 was read-only); this one additionally captures `method` and
/// `body` for the write/auth surface Phase 2 adds.
private actor RecordingBodyStubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    private(set) var capturedMethod: HTTPRequest.Method?
    private(set) var capturedPath: String?
    private(set) var capturedHeaderFields: HTTPFields?
    private(set) var capturedBodyData: Data?

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedMethod = request.method
        capturedPath = request.path
        capturedHeaderFields = request.headerFields
        capturedBodyData = try? await Data(collecting: body ?? HTTPBody(), upTo: 10 * 1024 * 1024)

        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves `PiefedClient`'s write/auth surface (Phase 2): the hand-rolled `send` engine builds a
/// `POST`/`PUT /api/alpha/...` `HTTPRequest` with the expected JSON body, bearer header (or its
/// absence, for `login`), and `Content-Type: application/json`, issues it through the injected
/// `ClientTransport`, and decodes the response into the Task-1 PieFed write/auth wire models -- or
/// maps a non-2xx PieFed error envelope (all three observed shapes) into `LemmyApiError.serverError`.
struct PiefedWriteClientTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// Wraps a fixture's raw JSON object under a new top-level key, for routes whose response
    /// wrapper key isn't what the fixture itself pins (e.g. `piefed-replies_item.json` is a bare
    /// `CommentReplyView`; `comment/mark_as_read` wraps it under `comment_reply_view`).
    private func wrapFixture(_ name: String, underKey key: String) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: fixture(name))
        return try JSONSerialization.data(withJSONObject: [key: object])
    }

    private func makeClient(transport: any ClientTransport, token: String? = nil) -> PiefedClient {
        PiefedClient(
            baseURL: URL(string: "https://piefed.example.invalid")!,
            token: token,
            transport: transport,
            userAgent: "LemmyKit-test"
        )
    }

    private func bodyObject(_ data: Data?) throws -> NSDictionary {
        let data = try #require(data)
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? NSDictionary)
    }

    // MARK: - Login (no auth header; bearer JWT decode)

    @Test
    func loginIssuesPostWithNoAuthHeaderAndDecodesJwt() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-login"))
        let client = makeClient(transport: transport, token: nil)

        let response = try await client.login(username: "u", password: "p")

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        let headerFields = await transport.capturedHeaderFields
        #expect(method == .post)
        #expect(path == "/api/alpha/user/login")
        #expect(headerFields?[.authorization] == nil)
        #expect(headerFields?[.contentType] == "application/json")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["username": "u", "password": "p"])
        #expect(response.jwt == "fixture.jwt.value")
    }

    // MARK: - Identity / counts

    @Test
    func userMeIssuesGetAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-user_me"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.userMe()

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        let headerFields = await transport.capturedHeaderFields
        #expect(method == .get)
        #expect(path == "/api/alpha/user/me")
        #expect(headerFields?[.authorization] == "Bearer abc123")
        #expect(response.local_user_view.person.user_name == "mark")
    }

    @Test
    func getSiteAuthedForwardsToSiteRouteAndDecodesMyUser() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-site_authed"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.getSiteAuthed()

        let path = await transport.capturedPath
        #expect(path == "/api/alpha/site")
        #expect(response.my_user?.local_user_view.person.user_name == "mark")
    }

    @Test
    func unreadCountIssuesGetAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-unread_count"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.unreadCount()

        let path = await transport.capturedPath
        #expect(path == "/api/alpha/user/unread_count")
        #expect(response.replies == 0)
    }

    // MARK: - Vote

    @Test
    func likePostIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.likePost(postId: 13, score: 1)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        let headerFields = await transport.capturedHeaderFields
        #expect(method == .post)
        #expect(path == "/api/alpha/post/like")
        #expect(headerFields?[.authorization] == "Bearer abc123")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "score": 1])
        #expect(response.post_view.post.id == 13)
    }

    @Test
    func likeCommentIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.likeComment(commentId: 7, score: -1)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/comment/like")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["comment_id": 7, "score": -1])
    }

    // MARK: - Save (PUT, not POST)

    @Test
    func savePostIssuesPutWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.savePost(postId: 13, save: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .put)
        #expect(path == "/api/alpha/post/save")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "save": true])
    }

    @Test
    func saveCommentIssuesPutWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.saveComment(commentId: 7, save: false)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .put)
        #expect(path == "/api/alpha/comment/save")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["comment_id": 7, "save": false])
    }

    // MARK: - Follow

    @Test
    func followCommunityIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-community_follow"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.followCommunity(communityId: 1, follow: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/community/follow")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["community_id": 1, "follow": true])
        #expect(response.community_view.subscribed == "Subscribed")
    }

    // MARK: - Mark post read / hide

    @Test
    func markPostAsReadIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-success"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.markPostAsRead(postId: 13, read: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/post/mark_as_read")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "read": true])
        #expect(response.success == true)
    }

    @Test
    func hidePostIssuesPostWithHiddenKeyMapping() async throws {
        // The wire key is `hidden`, not `hide` -- the request struct must map the Swift
        // parameter name to PieFed's `HidePostRequest.hidden` field, not send a `hide` key.
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.hidePost(postId: 13, hide: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/post/hide")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "hidden": true])
    }

    // MARK: - Comment create / edit / delete

    @Test
    func createCommentIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.createComment(body: "hello", postId: 13, parentId: nil, languageId: nil)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/comment")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["body": "hello", "post_id": 13])
        #expect(response.comment_view.comment.id == 7)
    }

    @Test
    func createCommentOmitsNilOptionalFields() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.createComment(body: "hello", postId: 13, parentId: 6, languageId: 2)

        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["body": "hello", "post_id": 13, "parent_id": 6, "language_id": 2])
    }

    @Test
    func editCommentIssuesPutWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.editComment(commentId: 7, body: "edited", languageId: nil)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .put)
        #expect(path == "/api/alpha/comment")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["comment_id": 7, "body": "edited"])
    }

    @Test
    func deleteCommentIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-comment_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.deleteComment(commentId: 7, deleted: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/comment/delete")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["comment_id": 7, "deleted": true])
    }

    // MARK: - Post create / edit / delete

    @Test
    func createPostIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.createPost(
            communityId: 1, title: "Title", body: "Body", url: nil, nsfw: false, languageId: nil
        )

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/post")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["community_id": 1, "title": "Title", "body": "Body", "nsfw": false])
        #expect(response.post_view.post.id == 13)
    }

    @Test
    func editPostIssuesPutWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.editPost(postId: 13, title: "New title", body: nil, url: nil, nsfw: nil)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .put)
        #expect(path == "/api/alpha/post")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "title": "New title"])
    }

    @Test
    func deletePostIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-post_response"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.deletePost(postId: 13, deleted: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/post/delete")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["post_id": 13, "deleted": true])
    }

    // MARK: - Inbox (replies / mentions / mark-read)

    @Test
    func getRepliesIssuesExpectedQueryAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-replies"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.getReplies(unreadOnly: true, page: 1)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath ?? ""
        #expect(method == .get)
        #expect(path.hasPrefix("/api/alpha/user/replies"))
        #expect(path.contains("unread_only=true"))
        #expect(path.contains("page=1"))
        #expect(response.replies.isEmpty)
    }

    @Test
    func getMentionsIssuesExpectedQueryAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-replies"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.getMentions(unreadOnly: false, page: 2)

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/user/mentions"))
        #expect(path.contains("unread_only=false"))
        #expect(path.contains("page=2"))
    }

    @Test
    func markCommentReplyAsReadIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(
            responseBody: wrapFixture("piefed-replies_item", underKey: "comment_reply_view")
        )
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.markCommentReplyAsRead(commentReplyId: 1, read: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/comment/mark_as_read")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["comment_reply_id": 1, "read": true])
        #expect(response.comment_reply_view.comment_reply.id == 1)
    }

    @Test
    func markAllAsReadIssuesPostWithNoBody() async throws {
        let transport = RecordingBodyStubTransport(responseBody: Data(#"{"replies":[]}"#.utf8))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.markAllAsRead()

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/user/mark_all_as_read")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == [:])
        #expect(response.replies.isEmpty)
    }

    // MARK: - Private messages

    @Test
    func getPrivateMessagesIssuesExpectedQueryAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-pm_list"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.getPrivateMessages(unreadOnly: true, page: 1)

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/private_message/list"))
        #expect(path.contains("unread_only=true"))
        #expect(path.contains("page=1"))
        #expect(response.private_messages.isEmpty)
    }

    @Test
    func createPrivateMessageIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(
            responseBody: wrapFixture("piefed-pm_view", underKey: "private_message_view")
        )
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.createPrivateMessage(content: "hi", recipientId: 1)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/private_message")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["content": "hi", "recipient_id": 1])
        #expect(response.private_message_view.private_message.content == "Synthetic DM body for fixture decoding")
    }

    @Test
    func markPrivateMessageAsReadIssuesPostWithExpectedBody() async throws {
        let transport = try RecordingBodyStubTransport(
            responseBody: wrapFixture("piefed-pm_view", underKey: "private_message_view")
        )
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.markPrivateMessageAsRead(privateMessageId: 1, read: true)

        let method = await transport.capturedMethod
        let path = await transport.capturedPath
        #expect(method == .post)
        #expect(path == "/api/alpha/private_message/mark_as_read")
        let body = try await bodyObject(transport.capturedBodyData)
        #expect(body == ["private_message_id": 1, "read": true])
    }

    // MARK: - Person details

    @Test
    func getPersonDetailsIssuesExpectedQueryAndDecodes() async throws {
        let transport = try RecordingBodyStubTransport(responseBody: fixture("piefed-person_details"))
        let client = makeClient(transport: transport, token: "abc123")

        let response = try await client.getPersonDetails(personId: 10, includeContent: true)

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/user"))
        #expect(path.contains("person_id=10"))
        #expect(path.contains("include_content=true"))
        #expect(response.person_view.person.user_name == "mark")
    }

    // MARK: - Error-envelope mapping through the write engine (all three observed shapes)

    @Test
    func codeMessageStatusEnvelopeThrowsServerErrorWithMessageAsToken() async throws {
        let errorBody = Data(#"{"code":400,"message":"incorrect_login","status":"Bad Request"}"#.utf8)
        let transport = RecordingBodyStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport, token: "abc123")

        do {
            _ = try await client.likePost(postId: 13, score: 1)
            Issue.record("expected likePost to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "incorrect_login")
            #expect(errorResponse.message == "incorrect_login")
        }
    }

    @Test
    func messageOnlyEnvelopeThrowsServerErrorWithMessageAsToken() async throws {
        let errorBody = Data(#"{"message":"Something went wrong"}"#.utf8)
        let transport = RecordingBodyStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport, token: "abc123")

        do {
            _ = try await client.likePost(postId: 13, score: 1)
            Issue.record("expected likePost to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "Something went wrong")
            #expect(errorResponse.message == "Something went wrong")
        }
    }

    @Test
    func errorOnlyStubEnvelopeThrowsServerErrorWithErrorAsToken() async throws {
        let errorBody = Data(#"{"error":"not_yet_implemented"}"#.utf8)
        let transport = RecordingBodyStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport, token: "abc123")

        do {
            _ = try await client.likePost(postId: 13, score: 1)
            Issue.record("expected likePost to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "not_yet_implemented")
            #expect(errorResponse.message == nil)
        }
    }

    @Test
    func rateLimitedResponseThrowsUnknownServerErrorEvenWithDecodableEnvelope() async throws {
        // A 429 with a valid PieFed envelope must still surface as `.unknownServerError` (transient),
        // NOT `.serverError` (permanent), through the `send`/POST path too -- see
        // `mapNonSuccessResponse`'s doc comment.
        let errorBody = Data(#"{"error":"rate_limited"}"#.utf8)
        let transport = RecordingBodyStubTransport(status: 429, responseBody: errorBody)
        let client = makeClient(transport: transport, token: "abc123")

        do {
            _ = try await client.likePost(postId: 13, score: 1)
            Issue.record("expected likePost to throw")
        } catch let LemmyApiError.unknownServerError(httpStatusCode, _) {
            #expect(httpStatusCode == 429)
        }
    }

    @Test
    func serverErrorResponseThrowsUnknownServerErrorEvenWithDecodableEnvelope() async throws {
        // A 5xx with a valid PieFed envelope must still surface as `.unknownServerError` (transient),
        // NOT `.serverError` (permanent), through the `send`/POST path too -- see
        // `mapNonSuccessResponse`'s doc comment.
        let errorBody = Data(#"{"message":"Internal Server Error"}"#.utf8)
        let transport = RecordingBodyStubTransport(status: 500, responseBody: errorBody)
        let client = makeClient(transport: transport, token: "abc123")

        do {
            _ = try await client.likePost(postId: 13, score: 1)
            Issue.record("expected likePost to throw")
        } catch let LemmyApiError.unknownServerError(httpStatusCode, _) {
            #expect(httpStatusCode == 500)
        }
    }
}
