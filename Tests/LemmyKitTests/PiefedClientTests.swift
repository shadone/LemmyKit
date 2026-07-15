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
/// `HTTPRequest` it was sent -- both the path (query string included) and the header fields --
/// so tests can assert on what `PiefedClient` builds without hitting the network. Modeled on
/// `GetListNeutralTests.swift`'s `PathCapturingStubTransport` / `LemmyApiWrapperTests.swift`'s
/// `RecordingTransport`, combined into one stub since these tests need both path and headers.
private actor RecordingStubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    private(set) var capturedPath: String?
    private(set) var capturedHeaderFields: HTTPFields?

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
        capturedHeaderFields = request.headerFields

        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves `PiefedClient`'s hand-rolled transport call end-to-end: it builds a `GET
/// /api/alpha/...` `HTTPRequest` with the expected query params and bearer header, issues it
/// through the injected `ClientTransport`, and decodes the response into the Task-1 PieFed wire
/// models -- or maps a non-2xx PieFed error envelope into `LemmyApiError.serverError`.
struct PiefedClientTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private func makeClient(transport: any ClientTransport, token: String? = nil) -> PiefedClient {
        PiefedClient(
            baseURL: URL(string: "https://piefed.example.invalid")!,
            token: token,
            transport: transport,
            userAgent: "LemmyKit-test"
        )
    }

    @Test
    func getPostsIssuesExpectedRequestAndDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_list"))
        let client = makeClient(transport: transport)

        let response = try await client.getPosts(
            type_: "Local", sort: "Hot", communityId: 123, showNsfw: true, limit: 3, page: 2
        )

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/post/list"))
        #expect(path.contains("type_=Local"))
        #expect(path.contains("sort=Hot"))
        #expect(path.contains("community_id=123"))
        #expect(path.contains("show_nsfw=true"))
        #expect(path.contains("limit=3"))
        #expect(path.contains("page=2"))

        #expect(response.posts.count == 3)
        #expect(response.posts.first?.post.id == 2_210_778)
        #expect(response.posts.first?.post.title.contains("Blue Beetle") == true)
    }

    @Test
    func getPostsOmitsNilQueryParams() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_list"))
        let client = makeClient(transport: transport)

        _ = try await client.getPosts()

        let path = await transport.capturedPath ?? ""
        #expect(path == "/api/alpha/post/list")
    }

    @Test
    func authorizationHeaderPresentWhenTokenSupplied() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_list"))
        let client = makeClient(transport: transport, token: "abc123")

        _ = try await client.getPosts()

        let headerFields = await transport.capturedHeaderFields
        #expect(headerFields?[.authorization] == "Bearer abc123")
    }

    @Test
    func authorizationHeaderAbsentWhenNoTokenSupplied() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_list"))
        let client = makeClient(transport: transport, token: nil)

        _ = try await client.getPosts()

        let headerFields = await transport.capturedHeaderFields
        #expect(headerFields?[.authorization] == nil)
    }

    @Test
    func userAgentHeaderAlwaysPresent() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_list"))
        let client = makeClient(transport: transport)

        _ = try await client.getPosts()

        let headerFields = await transport.capturedHeaderFields
        #expect(headerFields?[.userAgent] == "LemmyKit-test")
    }

    @Test
    func nonTwoHundredResponseThrowsServerErrorWithMappedFields() async throws {
        // Precedence is message ?? error ?? status ?? code -- `message` wins here, matching a
        // real captured PieFed login failure (`{code,message,status}`).
        let errorBody = Data(#"{"code":400,"message":"incorrect_login","status":"Bad Request"}"#.utf8)
        let transport = RecordingStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport)

        do {
            _ = try await client.getPosts()
            Issue.record("expected getPosts to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "incorrect_login")
            #expect(errorResponse.message == "incorrect_login")
        }
    }

    @Test
    func messageOnlyEnvelopeThrowsServerErrorWithMessageAsToken() async throws {
        // The spec's declared `DefaultError` shape -- `{message}` only, no `code`/`status`/`error`.
        let errorBody = Data(#"{"message":"Something went wrong"}"#.utf8)
        let transport = RecordingStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport)

        do {
            _ = try await client.getPosts()
            Issue.record("expected getPosts to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "Something went wrong")
            #expect(errorResponse.message == "Something went wrong")
        }
    }

    @Test
    func errorOnlyStubEnvelopeThrowsServerErrorWithErrorAsToken() async throws {
        // A registered-but-unimplemented stub route (e.g. `password_reset`): `{"error":"..."}`,
        // no `message`/`code`/`status`.
        let errorBody = Data(#"{"error":"not_yet_implemented"}"#.utf8)
        let transport = RecordingStubTransport(status: 400, responseBody: errorBody)
        let client = makeClient(transport: transport)

        do {
            _ = try await client.getPosts()
            Issue.record("expected getPosts to throw")
        } catch let LemmyApiError.serverError(errorResponse) {
            #expect(errorResponse.error == "not_yet_implemented")
            #expect(errorResponse.message == nil)
        }
    }

    @Test
    func undecodableErrorBodyThrowsUnknownServerError() async throws {
        let transport = RecordingStubTransport(status: 503, responseBody: Data("not json".utf8))
        let client = makeClient(transport: transport)

        do {
            _ = try await client.getPosts()
            Issue.record("expected getPosts to throw")
        } catch let LemmyApiError.unknownServerError(httpStatusCode, _) {
            #expect(httpStatusCode == 503)
        }
    }

    // MARK: - Remaining read endpoints, decoding through to the Task-1 response models

    @Test
    func getSiteDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-site"))
        let client = makeClient(transport: transport)

        let response = try await client.getSite()

        let path = await transport.capturedPath
        #expect(path == "/api/alpha/site")
        #expect(response.version == "1.7.5")
        #expect(response.site.name == "PieFed")
    }

    @Test
    func getPostIssuesIdQueryAndDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-post_detail"))
        let client = makeClient(transport: transport)

        let response = try await client.getPost(id: 2_210_778)

        let path = await transport.capturedPath
        #expect(path == "/api/alpha/post?id=2210778")
        #expect(response.post_view.post.id == 2_210_778)
        #expect(response.moderators?.count == 4)
    }

    @Test
    func getCommentsIssuesExpectedQueryAndDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-comment_list"))
        let client = makeClient(transport: transport)

        let response = try await client.getComments(postId: 2_210_082, sort: "Hot", maxDepth: 3)

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/comment/list"))
        #expect(path.contains("post_id=2210082"))
        #expect(path.contains("sort=Hot"))
        #expect(path.contains("max_depth=3"))
        #expect(response.comments.count == 10)
    }

    @Test
    func listCommunitiesIssuesExpectedQueryAndDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-community_list"))
        let client = makeClient(transport: transport)

        let response = try await client.listCommunities(type_: "Local", sort: "Hot", limit: 20, page: 1)

        let path = await transport.capturedPath ?? ""
        #expect(path.contains("type_=Local"))
        #expect(path.contains("sort=Hot"))
        #expect(path.contains("limit=20"))
        #expect(path.contains("page=1"))
        #expect(response.communities.count == 3)
    }

    @Test
    func searchRequiresTypeAndDecodesResponse() async throws {
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-search"))
        let client = makeClient(transport: transport)

        let response = try await client.search(q: "movies", type_: "Communities")

        let path = await transport.capturedPath ?? ""
        #expect(path.hasPrefix("/api/alpha/search"))
        #expect(path.contains("q=movies"))
        #expect(path.contains("type_=Communities"))
        #expect(response.type_ == "Communities")
        #expect(response.communities.count == 3)
    }

    @Test
    func searchEscapesPlusAndSubDelimsInQueryValue() async throws {
        // Regression test: `URLComponents`/`URLQueryItem` leave `+` and several RFC-3986
        // sub-delimiters raw in a query value. PieFed's Flask/Werkzeug backend (`parse_qsl`)
        // decodes a raw `+` as a literal space, so `search(q: "c++")` would silently corrupt
        // the query server-side to `"c  "`. The query builder must percent-encode against an
        // unreserved-only set so `+` -> `%2B`, space -> `%20`, and `&` -> `%26`.
        let transport = try RecordingStubTransport(responseBody: fixture("piefed-search"))
        let client = makeClient(transport: transport)

        _ = try await client.search(q: "c++ & tags", type_: "Posts")

        let path = await transport.capturedPath ?? ""
        #expect(path.contains("q=c%2B%2B%20%26%20tags"))
        #expect(!path.contains("q=c++"))
        #expect(!path.contains("c++ "))
        #expect(!path.contains("c++&"))
    }

    @Test
    func resolveObjectIssuesQAndDecodesResponse() async throws {
        // resolve_object returns a bare `{"community": <CommunityView>}` (exactly one of its four
        // fields non-nil, per `PiefedResolveObjectResponse`'s doc comment); reuse a community_list
        // entry's shape by wrapping the first list item, since no dedicated fixture was captured.
        let community = try firstListedCommunity()
        let firstCommunity = try #require(community)
        let wrapped = try JSONSerialization.data(withJSONObject: ["community": firstCommunity])

        let transport = RecordingStubTransport(responseBody: wrapped)
        let client = makeClient(transport: transport)

        let response = try await client.resolveObject(q: "https://piefed.social/c/movies")

        // The `q` value is percent-encoded against the unreserved-only set (see
        // `percentEncodeQueryValueEscapesSubDelimsAndPlus` below), so `:` and `/` are escaped too.
        let path = await transport.capturedPath
        #expect(path == "/api/alpha/resolve_object?q=https%3A%2F%2Fpiefed.social%2Fc%2Fmovies")
        #expect(response.community != nil)
        #expect(response.post == nil)
    }

    @Test
    func getCommunityIssuesIdQueryAndDecodesResponse() async throws {
        // No dedicated `getCommunity` fixture was captured (see `PiefedGetCommunityResponse`'s
        // doc comment) -- build a minimal-but-valid response from the community_list fixture's
        // first entry plus an empty moderators/discussion_languages list.
        let community = try firstListedCommunity()
        let firstCommunity = try #require(community)
        let wrapped = try JSONSerialization.data(withJSONObject: [
            "community_view": firstCommunity,
            "moderators": [],
            "discussion_languages": [],
        ])

        let transport = RecordingStubTransport(responseBody: wrapped)
        let client = makeClient(transport: transport)

        let response = try await client.getCommunity(id: 15339)

        let path = await transport.capturedPath
        #expect(path == "/api/alpha/community?id=15339")
        #expect(response.community_view.community.id == 15339)
    }

    /// The first entry of the `piefed-community_list` fixture's `communities` array, as a raw
    /// JSON object -- reused to synthesize response bodies for endpoints without their own
    /// captured fixture (`resolve_object`, `community`).
    private func firstListedCommunity() throws -> [String: Any]? {
        let root = try JSONSerialization.jsonObject(with: fixture("piefed-community_list")) as? [String: Any]
        return (root?["communities"] as? [[String: Any]])?.first
    }
}
