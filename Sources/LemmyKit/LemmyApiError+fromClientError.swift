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

        assertionFailure("Got unexpected error \(error)")
        self = .unknown(error)
    }
}
