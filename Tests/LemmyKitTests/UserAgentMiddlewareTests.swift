//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import HTTPTypes
import OpenAPIRuntime
import XCTest
@testable import LemmyKit

final class UserAgentMiddlewareTests: XCTestCase {
    func test_setsUserAgentHeader() async throws {
        let middleware = UserAgentMiddleware(userAgent: "Spud/9.9")

        var seenUserAgent: String?
        _ = try await middleware.intercept(
            HTTPRequest(method: .get, scheme: "https", authority: "example.test", path: "/"),
            body: nil,
            baseURL: XCTUnwrap(URL(string: "https://example.test")),
            operationID: "getSite"
        ) { request, _, _ in
            seenUserAgent = request.headerFields[.userAgent]
            return (HTTPResponse(status: .ok), nil)
        }

        XCTAssertEqual(seenUserAgent, "Spud/9.9")
    }

    func test_overridesAnyExistingUserAgent() async throws {
        let middleware = UserAgentMiddleware(userAgent: "Spud/9.9")

        var request = HTTPRequest(method: .get, scheme: "https", authority: "example.test", path: "/")
        request.headerFields[.userAgent] = "CFNetwork/1.0"

        var seenUserAgent: String?
        _ = try await middleware.intercept(
            request,
            body: nil,
            baseURL: XCTUnwrap(URL(string: "https://example.test")),
            operationID: "getSite"
        ) { request, _, _ in
            seenUserAgent = request.headerFields[.userAgent]
            return (HTTPResponse(status: .ok), nil)
        }

        XCTAssertEqual(seenUserAgent, "Spud/9.9")
    }
}
