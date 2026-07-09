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
/// asserted, not only the returned neutral view. Same shape as `GetPostNeutralTests.swift`'s
/// `StubTransport`, plus body capture.
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

/// Proves the neutral mutation endpoints end-to-end -- vote/save on post & comment, plus hide
/// post -- following the vertical `GetPostNeutralTests.swift` established: facade dispatch on
/// `ApiVersion`, generated client call, neutral mapping. Because these are writes (not reads),
/// the vote and hide tests additionally capture the *outgoing* request body to prove the write
/// direction (`score`/`is_upvote`, `post_ids`/`post_id`), not just the returned neutral view.
final class MutationNeutralTests: XCTestCase {
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

    // MARK: votePostNeutral

    func testVotePostNeutralV3UpSendsScoreOneAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.votePostNeutral(id: 180, direction: .up)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["score"] as? Int, 1)
        XCTAssertEqual(body["post_id"] as? Int, 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertEqual(postView.myVote, .up)
    }

    func testVotePostNeutralV4UpSendsIsUpvoteTrueAndReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.votePostNeutral(id: 180, direction: .up)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["is_upvote"] as? Bool, true)
        XCTAssertEqual(body["post_id"] as? Int, 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertEqual(postView.myVote, .up)
    }

    func testVotePostNeutralV3NoneSendsScoreZero() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        _ = try await api.votePostNeutral(id: 180, direction: .none)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["score"] as? Int, 0)
    }

    func testVotePostNeutralV4NoneSendsNilIsUpvote() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        _ = try await api.votePostNeutral(id: 180, direction: .none)

        let body = try await capturedJSONBody(transport)
        // `is_upvote` is optional and `nil` for `.none`; the generated request encodes an absent
        // optional by omitting the key (`encodeIfPresent`), so there must be no non-nil value.
        XCTAssertNil(body["is_upvote"] as? Bool)
    }

    // MARK: voteCommentNeutral

    func testVoteCommentNeutralV3UpSendsScoreOneAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let commentView = try await api.voteCommentNeutral(id: 501, direction: .up)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["score"] as? Int, 1)
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
        XCTAssertEqual(commentView.myVote, .up)
    }

    func testVoteCommentNeutralV4UpSendsIsUpvoteTrueAndReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let commentView = try await api.voteCommentNeutral(id: 501, direction: .up)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["is_upvote"] as? Bool, true)
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
        XCTAssertEqual(commentView.myVote, .up)
    }

    // MARK: savePostNeutral

    func testSavePostNeutralV3ReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let postView = try await api.savePostNeutral(id: 180, saved: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["save"] as? Bool, true)
        XCTAssertEqual(body["post_id"] as? Int, 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertTrue(postView.isSaved)
    }

    func testSavePostNeutralV4ReturnsNeutralPostView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let postView = try await api.savePostNeutral(id: 180, saved: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["save"] as? Bool, true)
        XCTAssertEqual(body["post_id"] as? Int, 180)

        XCTAssertEqual(postView.post.id, 180)
        XCTAssertTrue(postView.isSaved)
    }

    // MARK: saveCommentNeutral

    func testSaveCommentNeutralV3ReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let commentView = try await api.saveCommentNeutral(id: 501, saved: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["save"] as? Bool, true)
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
        XCTAssertTrue(commentView.isSaved)
    }

    func testSaveCommentNeutralV4ReturnsNeutralCommentView() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("commentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let commentView = try await api.saveCommentNeutral(id: 501, saved: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["save"] as? Bool, true)
        XCTAssertEqual(body["comment_id"] as? Int, 501)

        XCTAssertEqual(commentView.comment.id, 501)
        XCTAssertTrue(commentView.isSaved)
    }

    // MARK: hidePostNeutral

    /// v3's `HidePost` request carries an *array* of post ids, even for a single post.
    func testHidePostNeutralV3SendsPostIdsArrayAndSucceeds() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("successResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.hidePostNeutral(id: 180, hidden: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_ids"] as? [Int], [180])
        XCTAssertEqual(body["hide"] as? Bool, true)
    }

    /// v4's `HidePost` request carries a single scalar post id, unlike v3's array, and its
    /// response is a full `PostResponse` (not a bare `SuccessResponse` like v3) -- both simply
    /// need to not throw.
    func testHidePostNeutralV4SendsScalarPostIdAndSucceeds() async throws {
        let transport = try CapturingStubTransport(responseBody: fixtureData("postResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.hidePostNeutral(id: 180, hidden: true)

        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["post_id"] as? Int, 180)
        XCTAssertEqual(body["hide"] as? Bool, true)
    }
}
