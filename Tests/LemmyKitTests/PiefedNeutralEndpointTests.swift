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

/// A `ClientTransport` that routes by request path, returning a canned fixture body per path --
/// needed because a `.piefed`-backed `LemmyApi` in these tests calls several different
/// `/api/alpha/*` routes across a single test (or across the suite), each of which must return
/// its own fixture. Matches `NotificationsNeutralTests.swift`'s `PathRoutingStubTransport`
/// pattern, minus its XCTest-specific `XCTFail` (this suite is Swift Testing).
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
        // Try an exact match on the full path (including its query string) first -- this lets a
        // single route (e.g. "/api/alpha/search") be registered multiple times with different
        // fixtures depending on its query (see the `.all` fan-out test, which distinguishes the
        // four sub-requests by their `type_` param) -- then fall back to a match on just the path
        // component (before any "?"), which is all the rest of this suite needs.
        let fullPath = request.path ?? ""
        let pathWithoutQuery = fullPath.split(separator: "?", maxSplits: 1).first.map(String.init) ?? fullPath

        guard let responseBody = responseBodiesByPath[fullPath] ?? responseBodiesByPath[pathWithoutQuery] else {
            Issue.record("Unexpected request path: \(fullPath)")
            return (HTTPResponse(status: .init(code: 404)), HTTPBody("{}".data(using: .utf8)!))
        }

        var response = HTTPResponse(status: .init(code: 200))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// End-to-end coverage for the eight read endpoints' `.piefed` dispatch: `LemmyApi`'s
/// `apiVersion == .piefed` now calls `PiefedClient` and maps the response through the Task-4
/// `neutralX(fromPiefed:)` adapters, replacing the `unsupportedByDialect` throw
/// `PiefedDialectTests.swift` proved before this task. Each test decodes a real captured
/// `piefed-*.json` fixture (see `Tests/LemmyKitTests/Fixtures/`), so assertions are pinned to
/// actual live-instance values, not tautological placeholders -- the same discipline
/// `GetPostNeutralTests.swift` established for the v3/v4 dispatch.
struct PiefedNeutralEndpointTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    /// A `.piefed`-backed `LemmyApi` whose transport routes every `/api/alpha/*` route used below
    /// to its own fixture -- covers `getSiteNeutral`, `getPostsNeutral`, `getPostNeutral`,
    /// `getCommentsNeutral` (both overloads), `getCommunityNeutral`, `listCommunitiesNeutral`, a
    /// `.communities`-type `searchNeutral`, and `resolveObjectNeutral`.
    private func makeApi() throws -> LemmyApi {
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/alpha/site": fixture("piefed-site"),
            "/api/alpha/post/list": fixture("piefed-post_list"),
            "/api/alpha/post": fixture("piefed-post_detail"),
            "/api/alpha/comment/list": fixture("piefed-comment_list"),
            "/api/alpha/community": fixture("piefed-community"),
            "/api/alpha/community/list": fixture("piefed-community_list"),
            "/api/alpha/search": fixture("piefed-search"),
            "/api/alpha/resolve_object": fixture("piefed-resolve_object"),
        ])
        return LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: nil,
            transport: transport,
            apiVersion: .piefed
        )
    }

    // MARK: - getSiteNeutral

    @Test
    func getSiteNeutralReturnsNeutralSiteInfo() async throws {
        let api = try makeApi()
        let site = try await api.getSiteNeutral()

        #expect(site.version == "1.7.5")
        #expect(site.site.name == "PieFed")
        #expect(site.admins.count == 6)
    }

    // MARK: - getPostsNeutral

    @Test
    func getPostsNeutralReturnsNeutralPage() async throws {
        let api = try makeApi()
        let page = try await api.getPostsNeutral(listingType: .Local, sort: .new)

        #expect(page.items.count == 3)
        #expect(
            page.items.first?.post.name
                == "'Man of Tomorrow': Xolo Maridueña to Return as Blue Beetle in James Gunn's Sequel"
        )
        #expect(page.items.first?.post.creatorId == 176_409)
        #expect(page.items.first?.community.name == "movies")
        #expect(page.nextPage == Cursor(rawValue: "2"))
    }

    // MARK: - getPostNeutral

    @Test
    func getPostNeutralReturnsNeutralPostDetail() async throws {
        let api = try makeApi()
        let detail = try await api.getPostNeutral(id: 2_210_778)

        #expect(detail.post.post.id == 2_210_778)
        #expect(detail.post.community.name == "movies")
        #expect(detail.crossPosts.count == 1)
        #expect(detail.crossPosts.first?.community.name == "dcstudios")
    }

    // MARK: - getCommentsNeutral

    @Test
    func getCommentsNeutralByPostIdReturnsNeutralPage() async throws {
        let api = try makeApi()
        let page = try await api.getCommentsNeutral(postId: 2_210_082, sort: .hot)

        #expect(page.items.isEmpty == false)
        #expect(page.items.count == 10)
        #expect(page.items.first?.comment.content == "Keep making live action movies nobody wants. Do it over and over again. ")
        #expect(page.nextPage == Cursor(rawValue: "2"))
    }

    @Test
    func getCommentsNeutralByParentIdReturnsNeutralPage() async throws {
        // The parent-scoped overload hits the same `/api/alpha/comment/list` route -- reuses the
        // same fixture as the post-scoped test above, proving the second overload dispatches
        // through its own `getCommentsNeutralPiefed(parentId:sort:pageCursor:)` path.
        let api = try makeApi()
        let page = try await api.getCommentsNeutral(parentId: 12_115_800, sort: .hot)

        #expect(page.items.isEmpty == false)
    }

    // MARK: - getCommunityNeutral

    @Test
    func getCommunityNeutralReturnsNeutralCommunityView() async throws {
        let api = try makeApi()
        let view = try await api.getCommunityNeutral(id: 2615)

        #expect(view.community.name == "movies")
        #expect(view.community.posts == 2663)
    }

    // MARK: - listCommunitiesNeutral

    @Test
    func listCommunitiesNeutralReturnsNeutralPage() async throws {
        let api = try makeApi()
        let page = try await api.listCommunitiesNeutral(sort: .hot)

        #expect(page.items.count == 3)
        #expect(page.items.first?.community.name == "microblogs")
        #expect(page.nextPage == Cursor(rawValue: "2"))
    }

    // MARK: - searchNeutral

    @Test
    func searchNeutralCommunitiesReturnsPopulatedCommunities() async throws {
        let api = try makeApi()
        let results = try await api.searchNeutral(query: "technology", type: .communities)

        #expect(results.communities.count == 3)
        #expect(results.communities.first?.community.name == "technology")
        #expect(results.persons.isEmpty)
    }

    @Test
    func searchNeutralPersonsReturnsPopulatedPersons() async throws {
        // A dedicated instance whose `/api/alpha/search` route returns the real
        // `type_=Users` capture (`piefed-search_users.json`) -- `piefed-search.json` (used by the
        // `.communities` test above) is itself a `Communities`-type search, so its `users` array
        // is empty; this exercises the person-mapping path against real, non-synthetic data.
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/alpha/search": fixture("piefed-search_users"),
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: nil,
            transport: transport,
            apiVersion: .piefed
        )

        let results = try await api.searchNeutral(query: "rimu", type: .persons)

        #expect(results.persons.count == 10)
        #expect(results.persons.first?.person.name == "rimu")
        #expect(results.communities.isEmpty)
    }

    @Test
    func searchNeutralAllFansOutAndMergesFourTypes() async throws {
        // PieFed's `type_` has no "every kind of result" value (see `piefedSearchType(fromNeutral:)`
        // in `LemmyApi+SearchNeutral.swift`), so `.all` fans out into one request per concrete
        // type. Route by the exact outgoing path (including its `type_` query param) to prove all
        // four requests go out and are merged from the right sub-response -- `piefed-search.json`
        // (Communities-type; empty posts/comments/users) covers the Posts/Comments legs with an
        // empty-but-valid response, and `piefed-search_users.json` covers the Users leg with real
        // person data.
        let communitiesFixture = try fixture("piefed-search")
        let usersFixture = try fixture("piefed-search_users")
        let transport = try PathRoutingStubTransport(responseBodiesByPath: [
            "/api/alpha/search?q=technology&type_=Posts": communitiesFixture,
            "/api/alpha/search?q=technology&type_=Comments": communitiesFixture,
            "/api/alpha/search?q=technology&type_=Communities": communitiesFixture,
            "/api/alpha/search?q=technology&type_=Users": usersFixture,
        ])
        let api = LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: nil,
            transport: transport,
            apiVersion: .piefed
        )

        let results = try await api.searchNeutral(query: "technology", type: .all)

        #expect(results.posts.isEmpty)
        #expect(results.comments.isEmpty)
        #expect(results.communities.count == 3)
        #expect(results.persons.count == 10)
    }

    // MARK: - resolveObjectNeutral

    @Test
    func resolveObjectNeutralReturnsNeutralCommunity() async throws {
        let api = try makeApi()
        let resolved = try await api.resolveObjectNeutral(query: "https://piefed.social/c/movies")

        #expect(resolved?.community?.community.name == "movies")
    }
}
