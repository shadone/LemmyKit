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

/// A `ClientTransport` that returns a canned status for every request, or throws, so
/// ``ApiVersionProbe/detect(instanceUrl:transport:userAgent:)`` can be exercised end-to-end
/// without hitting the network. Mirrors `GetPostNeutralTests.StubTransport`.
private actor StubTransport: ClientTransport {
    private enum Outcome {
        case status(Int, Data)
        case failure
    }

    private let outcome: Outcome

    init(status: Int, responseBody: Data = Data("{}".utf8)) {
        outcome = .status(status, responseBody)
    }

    private init(failure: Void) {
        outcome = .failure
    }

    static func throwing() -> StubTransport {
        StubTransport(failure: ())
    }

    func send(
        _: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        switch outcome {
        case let .status(status, responseBody):
            var response = HTTPResponse(status: .init(code: status))
            response.headerFields[.contentType] = "application/json; charset=utf-8"
            return (response, HTTPBody(responseBody))

        case .failure:
            throw URLError(.timedOut)
        }
    }
}

/// Proves ``ApiVersionProbe``'s three outcomes: a `2xx` from `/api/v4/site` detects `.v4`, while a
/// `404` (the v3 shape -- the route doesn't exist) and any other failure (5xx, transport throw)
/// both fail safe to `.v3`.
final class ApiVersionProbeTests: XCTestCase {
    private let instanceUrl = URL(string: "https://example.invalid")!

    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    func testDetectReturnsV4On200() async throws {
        let version = try await ApiVersionProbe.detect(
            instanceUrl: instanceUrl,
            transport: StubTransport(status: 200, responseBody: fixtureData("getSiteResponseV4")),
            userAgent: nil
        )

        XCTAssertEqual(version, .v4)
    }

    func testDetectReturnsV3On404() async throws {
        let version = await ApiVersionProbe.detect(
            instanceUrl: instanceUrl,
            transport: StubTransport(status: 404),
            userAgent: nil
        )

        XCTAssertEqual(version, .v3)
    }

    func testDetectReturnsV3On500() async throws {
        let version = await ApiVersionProbe.detect(
            instanceUrl: instanceUrl,
            transport: StubTransport(status: 500),
            userAgent: nil
        )

        XCTAssertEqual(version, .v3)
    }

    func testDetectReturnsV3WhenTransportThrows() async throws {
        let version = await ApiVersionProbe.detect(
            instanceUrl: instanceUrl,
            transport: StubTransport.throwing(),
            userAgent: "LemmyKitTests"
        )

        XCTAssertEqual(version, .v3)
    }
}
