//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime

extension LemmyApiError {
    init(from error: Error) {
        if let clientError = error as? ClientError {
            self = .init(from: clientError)
            return
        }

        assertionFailure("Got unexpected error \(error)")
        self = .unknown(error)
    }

    init(from error: ClientError) {
        if let underlyingError = error.underlyingError as? DecodingError {
            self = .failedToDeserializeResponse(underlyingError: underlyingError)
            return
        }

        if (error.underlyingError as NSError).domain == NSURLErrorDomain {
            self = .network(error.underlyingError)
            return
        }

        // Here be dragons...
        //
        // Don't know what the error is, it could be a bug in LemmyKit or it could be an internal
        // OpenAPIRuntime error.
        // For example the `error.underlayingError` could be of type `OpenAPIRuntime.RuntimeError`
        // when the server responds with unexpected content-type (e.g. we expect application/json
        // but the server is down and returned us text/html). Unfortunately the `RuntimeError` is
        // an internal type that we don't have access to.

        if let status = error.response?.status {
            self = .unknownServerError(httpStatusCode: status.code, error: error)
            return
        }

        self = .unknown(error)
    }
}
