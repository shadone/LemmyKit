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

/// Covers ``LemmyApiError``'s classification of `ClientError`s from the generated
/// client. The mapping is plain branching logic that is easy to break silently
/// (e.g. reordering the checks), and error handling is exactly the kind of code
/// that rarely gets exercised by hand.
final class LemmyApiErrorTests: XCTestCase {
    private func clientError(underlying: Error, response: HTTPResponse? = nil) -> ClientError {
        ClientError(
            operationID: "test",
            operationInput: "input",
            response: response,
            causeDescription: "test",
            underlyingError: underlying
        )
    }

    func testDecodingErrorMapsToFailedToDeserialize() {
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad"))
        let error = LemmyApiError(from: clientError(underlying: decodingError))
        guard case .failedToDeserializeResponse = error else {
            return XCTFail("expected .failedToDeserializeResponse, got \(error)")
        }
    }

    func testURLErrorMapsToNetwork() {
        let urlError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let error = LemmyApiError(from: clientError(underlying: urlError))
        guard case .network = error else {
            return XCTFail("expected .network, got \(error)")
        }
    }

    // A non-decoding, non-URL error with an HTTP response should be classified by
    // its status code. (The URL-domain check runs first, so the underlying error
    // here must be some other domain.)
    func testServerStatusMapsToUnknownServerError() {
        let generic = NSError(domain: "SomeOtherDomain", code: 1)
        let response = HTTPResponse(status: .init(code: 503))
        let error = LemmyApiError(from: clientError(underlying: generic, response: response))
        guard case let .unknownServerError(httpStatusCode, _) = error else {
            return XCTFail("expected .unknownServerError, got \(error)")
        }
        XCTAssertEqual(httpStatusCode, 503)
    }

    func testUnclassifiedErrorMapsToUnknown() {
        let generic = NSError(domain: "SomeOtherDomain", code: 1)
        let error = LemmyApiError(from: clientError(underlying: generic))
        guard case .unknown = error else {
            return XCTFail("expected .unknown, got \(error)")
        }
    }
}
