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
/// sent, so ``LemmyApi/personDetailsNeutral(personId:)`` and
/// ``LemmyApi/personContentNeutral(personId:pageCursor:)`` can be exercised end-to-end (facade
/// dispatch, generated client call, JSON decode, neutral mapping) without hitting the network --
/// the same stub `GetPostNeutralTests.swift` uses.
private actor StubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// Proves the "hard" v3/v4 person emulation: v4 splits a person's profile (`GetPersonDetails`)
/// from their combined post/comment feed (`ListPersonContent`, a cursor-paginated `anyOf` of
/// `PostView`/`CommentView`), while v3's single `getPersonDetails` call returns the profile and
/// the feed (as two separate, uncombined `posts[]`/`comments[]` arrays) inline. See
/// `LemmyApi+GetPersonDetailsNeutral.swift` and `LemmyApi+ListPersonContentNeutral.swift` for the
/// dispatch and the v3 interleave-and-paginate emulation this exercises.
final class PersonNeutralTests: XCTestCase {
    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    // MARK: personDetailsNeutral

    func testPersonDetailsNeutralV3ReturnsCountsFromPersonAggregates() async throws {
        let transport = try StubTransport(responseBody: fixtureData("personDetailsResponseV3"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let details = try await api.personDetailsNeutral(personId: 14)

        XCTAssertEqual(details.personView.person.name, "seed_mod1")
        XCTAssertFalse(details.personView.isAdmin)
        // v3's `PersonView` has no ban-standing field at all -- always false.
        XCTAssertFalse(details.personView.isBanned)
        // v3 exposes no per-viewer relationship on this view -- always nil.
        XCTAssertNil(details.personView.personActions)
        XCTAssertEqual(details.personView.postCount, 5)
        XCTAssertEqual(details.personView.commentCount, 12)
        XCTAssertEqual(details.moderates, [29])
    }

    func testPersonDetailsNeutralV4ReturnsNilCountsAndBanStanding() async throws {
        let transport = try StubTransport(responseBody: fixtureData("personDetailsResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let details = try await api.personDetailsNeutral(personId: 14)

        XCTAssertEqual(details.personView.person.name, "seed_mod1")
        XCTAssertTrue(details.personView.isAdmin)
        // v4's own `banned` field, not derivable on v3 -- see the V3 test above.
        XCTAssertTrue(details.personView.isBanned)
        XCTAssertTrue(details.personView.isBlocked)
        // v4 dropped `PersonAggregates` -- counts live on `person.postCount`/`commentCount`
        // instead, never on the view itself.
        XCTAssertNil(details.personView.postCount)
        XCTAssertNil(details.personView.commentCount)
        XCTAssertEqual(details.personView.person.postCount, 8)
        XCTAssertEqual(details.personView.person.commentCount, 20)
        XCTAssertEqual(details.moderates, [29])
    }

    // MARK: personContentNeutral -- v4 combined feed

    func testPersonContentNeutralV4ReturnsMixedPostAndCommentItems() async throws {
        let transport = try StubTransport(responseBody: fixtureData("personContentResponseV4"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        let page = try await api.personContentNeutral(personId: 14)

        XCTAssertEqual(page.items.count, 2)
        guard case let .comment(commentView) = page.items[0] else {
            return XCTFail("expected the first item to be a .comment")
        }
        XCTAssertEqual(commentView.comment.id, 501)
        guard case let .post(postView) = page.items[1] else {
            return XCTFail("expected the second item to be a .post")
        }
        XCTAssertEqual(postView.post.id, 179)
        XCTAssertEqual(page.nextPage, Cursor(rawValue: "Pc20"))
        XCTAssertFalse(page.hasPrevPage)
    }

    // MARK: personContentNeutral -- v3 interleave emulation

    /// v3 has no combined feed endpoint at all: `personContentNeutral`'s v3 path re-fetches
    /// `getPersonDetails` and interleaves its separate `posts[]`/`comments[]` arrays by
    /// `publishedAt` descending. The fixture's 2 posts + 2 comments have deliberately staggered
    /// dates (post, comment, post, comment when sorted by recency) so a naive
    /// "posts-then-comments" concatenation would produce the wrong order and this test would
    /// catch it.
    func testPersonContentNeutralV3InterleavesPostsAndCommentsByPublishedDateDescending() async throws {
        let transport = try StubTransport(responseBody: fixtureData("personDetailsResponseV3Interleave"))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        let page = try await api.personContentNeutral(personId: 14)

        XCTAssertEqual(page.items.count, 4)

        guard
            case let .post(rank1) = page.items[0],
            case let .comment(rank2) = page.items[1],
            case let .post(rank3) = page.items[2],
            case let .comment(rank4) = page.items[3]
        else {
            return XCTFail("expected [.post, .comment, .post, .comment], got \(page.items)")
        }
        XCTAssertEqual(rank1.post.id, 301)
        XCTAssertEqual(rank2.comment.id, 501)
        XCTAssertEqual(rank3.post.id, 302)
        XCTAssertEqual(rank4.comment.id, 502)

        // Neither the posts nor the comments list came back a full page (limit 10), so this
        // first-pass emulation has no reason to believe there's more -- see
        // `LemmyApi+ListPersonContentNeutral.swift`'s doc.
        XCTAssertNil(page.nextPage)
        XCTAssertNil(page.prevPage)
    }
}
