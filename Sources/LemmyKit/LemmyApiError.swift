//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum LemmyApiError: Error {
    /// A network error has occurred.
    case network(Error)

    /// Failed to parse network response.
    case failedToDeserializeResponse(underlyingError: Error)

    /// Lemmy server returned a specified error.
    case serverError(Components.Schemas.ErrorResponse)

    /// Lemmy server returned an authorization error.
    case unauthorized(message: String?)

    /// Request to Lemmy server failed with an unexpected error.
    ///
    /// This is a catch-all case that should never happen, if it does we need to catch and handle errors better.
    case unknownServerError(httpStatusCode: Int)

    /// An unexpected error has occurred.
    ///
    /// This is a catch-all case that should never happen, if it does we need to catch and handle errors better.
    case unknown(Error)
}
