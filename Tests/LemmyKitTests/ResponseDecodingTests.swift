//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import XCTest
@testable import LemmyKit

/// Decodes captured Lemmy responses into the generated types.
///
/// These guard the class of spec/codegen bug found in the v3 audit — fields that
/// were missing from the spec (so the client silently dropped them) or had the
/// wrong required/optional (so a valid payload failed to decode). The capture
/// fixtures come from a live 0.19.x instance, so a passing run also confirms our
/// 0.19.11 types stay compatible with a server running a newer point release.
///
/// Decoding goes through a `JSONDecoder` wired to ``LemmyDateTranscoder`` so
/// Lemmy's microsecond timestamps decode exactly as the live client decodes them.
final class ResponseDecodingTests: XCTestCase {
    private func makeDecoder() -> JSONDecoder {
        let transcoder = LemmyDateTranscoder()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            return try transcoder.decode(try container.decode(String.self))
        }
        return decoder
    }

    private func decodeFixture<T: Decodable>(_ type: T.Type, _ name: String) throws -> T {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"),
            "missing fixture \(name).json"
        )
        return try makeDecoder().decode(type, from: Data(contentsOf: url))
    }

    // Richest payload: SiteView/Site, MyUserInfo, taglines, custom_emojis. Because
    // those fields are required (non-optional) in the generated types, a successful
    // decode is itself the assertion that the spec models them and the server sends
    // them (regressions S5, S7, R3, R4 from the audit).
    func testGetSiteResponseDecodes() throws {
        let response = try decodeFixture(Components.Schemas.GetSiteResponse.self, "getSiteResponse")
        // Authenticated /site -> my_user present, and instance_blocks is modeled.
        XCTAssertNotNil(response.my_user)
        XCTAssertNotNil(response.my_user?.instance_blocks)
        XCTAssertFalse(response.site_view.site.public_key.isEmpty)
    }

    // S6: PostAggregates.newest_comment_time is modeled (as a Date) and required.
    func testGetPostsResponseDecodes() throws {
        let response = try decodeFixture(Components.Schemas.GetPostsResponse.self, "getPostsResponse")
        XCTAssertFalse(response.posts.isEmpty)
        XCTAssertNotNil(response.posts.first?.counts.newest_comment_time)
    }

    // R6: CommunityAggregates.subscribers_local is required and present.
    func testListCommunitiesResponseDecodes() throws {
        let response = try decodeFixture(Components.Schemas.ListCommunitiesResponse.self, "listCommunitiesResponse")
        XCTAssertFalse(response.communities.isEmpty)
    }

    // R2: federated_instances is optional; a real response decodes either way.
    func testGetFederatedInstancesResponseDecodes() throws {
        let response = try decodeFixture(
            Components.Schemas.GetFederatedInstancesResponse.self,
            "getFederatedInstancesResponse"
        )
        XCTAssertNotNil(response.federated_instances)
    }

    // R1 regression: an unresolved report omits `resolver_id`. The field used to be
    // marked required, so this payload threw a DecodingError; it must decode now,
    // with resolver_id == nil.
    func testUnresolvedPrivateMessageReportDecodes() throws {
        let report = try decodeFixture(
            Components.Schemas.PrivateMessageReport.self,
            "privateMessageReportUnresolved"
        )
        XCTAssertNil(report.resolver_id)
        XCTAssertFalse(report.resolved)
    }
}
