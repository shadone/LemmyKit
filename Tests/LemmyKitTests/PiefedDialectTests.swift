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

/// A `ClientTransport` that always fails if invoked -- used to prove that a `.piefed`-gated
/// neutral endpoint's `unsupportedByDialect` throw happens at the facade's `switch apiVersion`,
/// before any request is built or sent. A neutral endpoint that instead reached the network (or
/// `PiefedClient`) on `.piefed` and only failed there would be a bug this test needs to catch, not
/// paper over.
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

/// Proves Task 3's gating of the neutral facade for the `.piefed` dialect: every neutral endpoint
/// not yet ported to PieFed -- every write/auth endpoint, plus (until Task 5 lands) every read
/// endpoint too -- throws `LemmyApiError.unsupportedByDialect(operation:)` the moment
/// `LemmyApi.apiVersion == .piefed`, carrying the neutral method's own name (minus its `Neutral`
/// suffix) as `operation` so a caller/log can tell which endpoint was attempted. Also confirms
/// `LemmyApi` builds a `PiefedClient` only for `.piefed`, leaving it nil for `.v3`/`.v4` (see
/// `LemmyApi.swift`'s two inits).
struct PiefedDialectTests {
    private func makeApi(apiVersion: ApiVersion = .piefed, credential: LemmyCredential? = nil) -> LemmyApi {
        LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: credential,
            transport: NeverCalledTransport(),
            apiVersion: apiVersion
        )
    }

    // MARK: - piefedClient construction

    @Test
    func piefedClientIsBuiltWhenApiVersionIsPiefed() async {
        let api = makeApi(apiVersion: .piefed, credential: LemmyCredential(jwt: "test-token"))
        let client = await api.piefedClient
        #expect(client != nil)
    }

    @Test
    func piefedClientIsNilForV3() async {
        let api = makeApi(apiVersion: .v3)
        let client = await api.piefedClient
        #expect(client == nil)
    }

    @Test
    func piefedClientIsNilForV4() async {
        let api = makeApi(apiVersion: .v4)
        let client = await api.piefedClient
        #expect(client == nil)
    }

    // MARK: - Write/auth endpoints throw unsupportedByDialect

    @Test
    func votePostNeutralThrowsUnsupportedByDialect() async throws {
        let api = makeApi()
        do {
            _ = try await api.votePostNeutral(id: 1, direction: .up)
            Issue.record("expected votePostNeutral to throw on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "votePost")
        }
    }

    @Test
    func createCommentNeutralThrowsUnsupportedByDialect() async throws {
        let api = makeApi()
        do {
            _ = try await api.createCommentNeutral(content: "hi", postId: 1, parentId: nil, languageId: nil)
            Issue.record("expected createCommentNeutral to throw on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "createComment")
        }
    }

    @Test
    func followCommunityNeutralThrowsUnsupportedByDialect() async throws {
        let api = makeApi()
        do {
            _ = try await api.followCommunityNeutral(id: 1, follow: true)
            Issue.record("expected followCommunityNeutral to throw on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "followCommunity")
        }
    }

    @Test
    func hidePostNeutralThrowsUnsupportedByDialect() async throws {
        let api = makeApi()
        do {
            try await api.hidePostNeutral(id: 1, hidden: true)
            Issue.record("expected hidePostNeutral to throw on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "hidePost")
        }
    }

    @Test
    func loginNeutralThrowsUnsupportedByDialect() async throws {
        let api = makeApi()
        do {
            _ = try await api.loginNeutral(usernameOrEmail: "alice", password: "hunter2")
            Issue.record("expected loginNeutral to throw on .piefed")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "login")
        }
    }

    // MARK: - Read endpoints also throw for now (Task 5 replaces these eight with real calls)

    @Test
    func getSiteNeutralThrowsUnsupportedByDialectUntilTask5() async throws {
        let api = makeApi()
        do {
            _ = try await api.getSiteNeutral()
            Issue.record("expected getSiteNeutral to throw on .piefed pre-Task-5")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "getSite")
        }
    }

    @Test
    func getCommentsNeutralThrowsUnsupportedByDialectUntilTask5() async throws {
        let api = makeApi()
        do {
            _ = try await api.getCommentsNeutral(postId: 1, sort: .hot)
            Issue.record("expected getCommentsNeutral to throw on .piefed pre-Task-5")
        } catch let LemmyApiError.unsupportedByDialect(operation) {
            #expect(operation == "getComments")
        }
    }
}
