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

/// A `ClientTransport` that records the outgoing request and returns a canned
/// response, so the hand-written wrappers can be exercised without the network
/// via ``LemmyApi``'s test-only `init(instanceUrl:credential:transport:)`.
private actor RecordingTransport: ClientTransport {
    struct Recorded: Sendable {
        let method: HTTPRequest.Method
        let path: String
    }

    private(set) var recorded: Recorded?
    private let status: Int
    private let responseBody: Data

    init(status: Int = 200, responseBody: Data = Data("{}".utf8)) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        recorded = Recorded(method: request.method, path: request.path ?? "")
        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Exercises the request-building and response-branch logic in the
/// `LemmyApi+*` wrappers — the layer between the caller and the generated
/// client where mapping bugs hide.
final class LemmyApiWrapperTests: XCTestCase {
    private func makeApi(_ transport: any ClientTransport) -> LemmyApi {
        LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport
        )
    }

    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: Request mapping

    // E1 regression at the client boundary: registration must POST to
    // /api/v3/user/register (not the old /register).
    func testRegisterTargetsUserRegisterPath() async throws {
        let transport = RecordingTransport()
        _ = try? await makeApi(transport).register(username: "u", password: "p", passwordVerify: "p")
        let recorded = await transport.recorded
        XCTAssertEqual(recorded?.method, .post)
        XCTAssertEqual(recorded?.path, "/api/v3/user/register")
    }

    // The Filter set must translate into the saved_only / liked_only query flags.
    func testGetPostsMapsFilterToQueryFlags() async throws {
        let transport = RecordingTransport()
        let cursor: Components.Schemas.PaginationCursor? = nil
        _ = try? await makeApi(transport).getPosts(
            type: .All, sort: .New, filter: [.saved, .like(.liked)], page: cursor
        )
        let path = await transport.recorded?.path ?? ""
        XCTAssertTrue(path.hasPrefix("/api/v3/post/list"), "unexpected path: \(path)")
        XCTAssertTrue(path.contains("saved_only=true"), "missing saved_only: \(path)")
        XCTAssertTrue(path.contains("liked_only=true"), "missing liked_only: \(path)")
    }

    // MARK: Response branches

    // 200 + a real body decodes and is returned.
    func testGetPostsOkReturnsDecodedResponse() async throws {
        let transport = RecordingTransport(status: 200, responseBody: try fixtureData("getPostsResponse"))
        let cursor: Components.Schemas.PaginationCursor? = nil
        let response = try await makeApi(transport).getPosts(type: .All, sort: .New, page: cursor)
        XCTAssertFalse(response.posts.isEmpty)
    }

    // 401 maps to .unauthorized.
    func testGetPostsUnauthorizedThrowsUnauthorized() async throws {
        let body = Data(#"{"error":"incorrect_login","message":"nope"}"#.utf8)
        let transport = RecordingTransport(status: 401, responseBody: body)
        let cursor: Components.Schemas.PaginationCursor? = nil
        do {
            _ = try await makeApi(transport).getPosts(type: .All, sort: .New, page: cursor)
            XCTFail("expected to throw")
        } catch let error as LemmyApiError {
            guard case .unauthorized = error else {
                return XCTFail("expected .unauthorized, got \(error)")
            }
        }
    }

    // An undocumented status maps to .unknownServerError carrying that status.
    func testUndocumentedStatusThrowsUnknownServerError() async throws {
        let transport = RecordingTransport(status: 503, responseBody: Data("{}".utf8))
        let cursor: Components.Schemas.PaginationCursor? = nil
        do {
            _ = try await makeApi(transport).getPosts(type: .All, sort: .New, page: cursor)
            XCTFail("expected to throw")
        } catch let error as LemmyApiError {
            guard case let .unknownServerError(code, _) = error else {
                return XCTFail("expected .unknownServerError, got \(error)")
            }
            XCTAssertEqual(code, 503)
        }
    }
}
