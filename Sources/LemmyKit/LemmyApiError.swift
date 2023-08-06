//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum LemmyApiError: Error {
    /// Failed to create a network request due to an internal error.
    case failedToSerializeRequest(underlyingError: Error?)

    /// A network error has occurred.
    case network(Error)

    /// Received a response without data payload.
    case responseContainsNoData

    /// Faile to parse network response.
    case failedToDeserializeResponse(underlyingError: Error)

    /// Lemmy server returned a specified error.
    case serverError(LemmyServerError)

    /// Lemmy server is currently unavailable, returned 5XX status code.
    case serverUnavailable(httpStatusCode: Int)

    /// Request to Lemmy server failed with an unexpected error.
    /// This is a catch-all case that should never happen, if it does we need to catch and handle errors better.
    case unknownServerError(httpStatusCode: Int)
}
