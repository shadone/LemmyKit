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
/// sent, and additionally captures the *outgoing* request body -- so a mutation neutral
/// endpoint's write direction (which field it sends, not just what it decodes back) can be
/// asserted, not only the returned neutral view. Same shape as `MutationNeutralTests.swift`'s
/// `CapturingStubTransport`.
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

/// Proves the neutral content-mutation endpoints end-to-end -- create/edit/delete for post &
/// comment -- following the vertical `MutationNeutralTests.swift` established: facade dispatch
/// on `ApiVersion`, generated client call, neutral mapping. Because these are writes (not
/// reads), the create/delete tests additionally capture the *outgoing* request body to prove the
/// write direction (`name`/`community_id`/`body`, `deleted`, `content`/`post_id`/`parent_id`),
/// not just the returned neutral view.
final class ContentMutationNeutralTests: XCTestCase {
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

    // MARK: createPostNeutral

    func testCreatePostNeutralV3SendsFieldsAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.createPostNeutral(
            name: "Live recording (thread 8)",
            communityId: 29,
            url: "https://example.com/live",
            body: "Check this out",
            nsfw: false,
            languageId: nil
        )

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["name"] as? String, "Live recording (thread 8)")
        XCTAssertEqual(body["community_id"] as? Int, 29)
        XCTAssertEqual(body["body"] as? String, "Check this out")

        XCTAssertEqual(postView.post.id, 180)
    }

    func testCreatePostNeutralV4SendsFieldsAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.createPostNeutral(
            name: "Live recording (thread 8)",
            communityId: 29,
            url: "https://example.com/live",
            body: "Check this out",
            nsfw: false,
            languageId: nil
        )

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["name"] as? String, "Live recording (thread 8)")
        XCTAssertEqual(body["community_id"] as? Int, 29)
        XCTAssertEqual(body["body"] as? String, "Check this out")

        XCTAssertEqual(postView.post.id, 180)
    }

    // MARK: editPostNeutral

    func testEditPostNeutralV3ReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.editPostNeutral(id: 180, name: nil, url: nil, body: "Updated body", nsfw: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["body"] as? String, "Updated body")
        XCTAssertEqual(body["nsfw"] as? Bool, true)

        XCTAssertEqual(postView.post.id, 180)
    }

    func testEditPostNeutralV4ReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.editPostNeutral(id: 180, name: nil, url: nil, body: "Updated body", nsfw: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["body"] as? String, "Updated body")
        XCTAssertEqual(body["nsfw"] as? Bool, true)

        XCTAssertEqual(postView.post.id, 180)
    }

    // MARK: deletePostNeutral

    func testDeletePostNeutralV3SendsDeletedTrueAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.deletePostNeutral(id: 180, deleted: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["deleted"] as? Bool, true)

        XCTAssertEqual(postView.post.id, 180)
    }

    func testDeletePostNeutralV4SendsDeletedTrueAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.deletePostNeutral(id: 180, deleted: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["deleted"] as? Bool, true)

        XCTAssertEqual(postView.post.id, 180)
    }

    // MARK: createCommentNeutral

    func testCreateCommentNeutralV3SendsFieldsAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let commentView = try await api.createCommentNeutral(
            content: "Great track, thanks for sharing!",
            postId: 180,
            parentId: nil,
            languageId: nil
        )

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Great track, thanks for sharing!")
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertNil(body["parent_id"] as? Int)

        XCTAssertEqual(commentView.comment.id, 501)
    }

    func testCreateCommentNeutralV4SendsFieldsAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let commentView = try await api.createCommentNeutral(
            content: "Great track, thanks for sharing!",
            postId: 180,
            parentId: 42,
            languageId: nil
        )

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Great track, thanks for sharing!")
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["parent_id"] as? Int, 42)

        XCTAssertEqual(commentView.comment.id, 501)
    }

    // MARK: editCommentNeutral

    func testEditCommentNeutralV4SendsContentAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let commentView = try await api.editCommentNeutral(id: 501, content: "Edited comment")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Edited comment")
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
    }

    func testEditCommentNeutralV3SendsContentAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let commentView = try await api.editCommentNeutral(id: 501, content: "Edited comment")

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["content"] as? String, "Edited comment")
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
    }

    // MARK: deleteCommentNeutral

    func testDeleteCommentNeutralV3SendsDeletedTrueAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let commentView = try await api.deleteCommentNeutral(id: 501, deleted: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["comment_id"] as? Int, 501)
        XCTAssertEqual(body["deleted"] as? Bool, true)

        XCTAssertEqual(commentView.comment.id, 501)
    }

    func testDeleteCommentNeutralV4SendsDeletedTrueAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let commentView = try await api.deleteCommentNeutral(id: 501, deleted: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["comment_id"] as? Int, 501)
        XCTAssertEqual(body["deleted"] as? Bool, true)

        XCTAssertEqual(commentView.comment.id, 501)
    }
}
