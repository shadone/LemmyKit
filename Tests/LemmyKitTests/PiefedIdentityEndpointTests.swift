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

/// A `ClientTransport` that routes by request path (falling back from the full path incl. query
/// to the bare path, same as `PiefedNeutralEndpointTests.swift`'s `PathRoutingStubTransport`) and
/// additionally TALLIES how many times each generated `operationID` was invoked -- needed to prove
/// `getMyUserNeutral`/`getSiteAndMyUserNeutral`'s carry-forward requirement that PieFed sources
/// `MyUser` from the authed `getSite()` embed and never calls the dedicated `userMe()` route (see
/// `PiefedClient.userMe()`'s doc: its `follows` list is observed empty while the `/site` embed's
/// is populated). Mirrors `SiteMyUserNeutralTests.swift`'s `RoutingCountingTransport`, folded
/// together with the path-fallback routing `PiefedNeutralEndpointTests.swift` needs.
private actor RoutingCountingStubTransport: ClientTransport {
    private let responseBodiesByPath: [String: Data]
    private(set) var operationCounts: [String: Int] = [:]

    init(responseBodiesByPath: [String: Data]) {
        self.responseBodiesByPath = responseBodiesByPath
    }

    func count(for operationID: String) -> Int {
        operationCounts[operationID] ?? 0
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        operationCounts[operationID, default: 0] += 1

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

/// End-to-end coverage for the five my-user/site/person/unread endpoints' `.piefed` dispatch
/// (Phase 2, Task 5): `LemmyApi`'s `apiVersion == .piefed` now calls `PiefedClient`'s
/// identity/person surface and maps the response through the Task-3 `neutralX(fromPiefed:)`
/// adapters, replacing the `unsupportedByDialect` throw. Each test asserts the outgoing
/// route(+query) and the mapped neutral DTO, pinned against the real captured `piefed-*.json`
/// fixtures, following the discipline `PiefedNeutralEndpointTests.swift`/
/// `PiefedWriteEndpointTests.swift` established for Phase 2's other endpoints.
struct PiefedIdentityEndpointTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private func makeApi(_ transport: RoutingCountingStubTransport) -> LemmyApi {
        LemmyApi(
            instanceUrl: URL(string: "https://piefed.social")!,
            credential: LemmyCredential(jwt: "t"),
            transport: transport,
            apiVersion: .piefed
        )
    }

    // MARK: - getMyUserNeutral

    @Test
    func getMyUserNeutralSourcesFromAuthedSiteEmbedNotUserMe() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/site": fixture("piefed-site_authed"),
        ])
        let api = makeApi(transport)

        let myUser = try await api.getMyUserNeutral()

        // Sourced from the site embed (populated follows), not the dedicated user/me route.
        #expect(myUser.person.name == "mark")
        #expect(myUser.localUserId == 10)
        #expect(myUser.follows.map(\.name) == ["piefedtest"])

        // `piefed-site_authed.json`'s `admins` list carries only person id 1 ("admin"), not
        // mark's id 10 -- isAdmin must be derived false for this account, not defaulted true.
        #expect(myUser.isAdmin == false)

        let getSiteCount = await transport.count(for: "getSite")
        let userMeCount = await transport.count(for: "userMe")
        #expect(getSiteCount == 1)
        #expect(userMeCount == 0)
    }

    @Test
    func getMyUserNeutralThrowsUnauthorizedWhenSiteCarriesNoMyUser() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/site": fixture("piefed-site"),
        ])
        let api = makeApi(transport)

        do {
            _ = try await api.getMyUserNeutral()
            Issue.record("expected getMyUserNeutral to throw for a signed-out site response")
        } catch let LemmyApiError.unauthorized(message) {
            #expect(message == nil)
        }
    }

    // MARK: - getSiteAndMyUserNeutral

    @Test
    func getSiteAndMyUserNeutralIssuesExactlyOneAuthedSiteRequest() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/site": fixture("piefed-site_authed"),
        ])
        let api = makeApi(transport)

        let result = try await api.getSiteAndMyUserNeutral()

        let getSiteCount = await transport.count(for: "getSite")
        let userMeCount = await transport.count(for: "userMe")
        #expect(getSiteCount == 1)
        #expect(userMeCount == 0)

        #expect(result.site.version == "1.7.5")
        #expect(result.site.site.name == "PieFed")
        #expect(result.myUser?.person.name == "mark")
        #expect(result.myUser?.isAdmin == false)
    }

    @Test
    func getSiteAndMyUserNeutralToleratesMissingMyUserForSignedOutViewer() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/site": fixture("piefed-site"),
        ])
        let api = makeApi(transport)

        let result = try await api.getSiteAndMyUserNeutral()

        #expect(result.site.version == "1.7.5")
        #expect(result.myUser == nil)
    }

    // MARK: - unreadCountsNeutral

    @Test
    func unreadCountsNeutralMapsFixtureTotals() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/user/unread_count": fixture("piefed-unread_count"),
        ])
        let api = makeApi(transport)

        let counts = try await api.unreadCountsNeutral()

        // piefed-unread_count.json is all zeroes -- confirms the fields are read and summed
        // through the wiring, not that the account has unread activity.
        #expect(counts.total == 0)
        #expect(counts.replies == 0)
        #expect(counts.mentions == 0)
        #expect(counts.privateMessages == 0)
    }

    // MARK: - personDetailsNeutral

    @Test
    func personDetailsNeutralOmitsContentAndMapsProfilePlusModerates() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/user": fixture("piefed-person_details"),
        ])
        let api = makeApi(transport)

        let details = try await api.personDetailsNeutral(personId: 10)

        #expect(details.personView.person.name == "mark")
        // piefed-person_details.json's moderates list is community id 4 (`spudprobe_tmp`).
        #expect(details.moderates == [4])
    }

    // MARK: - personContentNeutral

    @Test
    func personContentNeutralSendsExplicitPageAndLimitAndInterleavesContent() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/user?person_id=10&include_content=true&page=1&limit=10":
                fixture("piefed-person_details"),
        ])
        let api = makeApi(transport)

        let page = try await api.personContentNeutral(personId: 10, pageCursor: nil)

        // The fixture has 0 posts and 1 comment -- both well under the page limit, so there is no
        // more content to fetch.
        #expect(page.items.count == 1)
        #expect(page.items.first?.comment != nil)
        #expect(page.nextPage == nil)
        #expect(page.prevPage == nil)
    }

    @Test
    func personContentNeutralResumesFromOpaqueCursor() async throws {
        let transport = try RoutingCountingStubTransport(responseBodiesByPath: [
            "/api/alpha/user?person_id=10&include_content=true&page=3&limit=10":
                fixture("piefed-person_details"),
        ])
        let api = makeApi(transport)

        let page = try await api.personContentNeutral(personId: 10, pageCursor: Cursor(rawValue: "3"))

        #expect(page.items.count == 1)
    }
}
