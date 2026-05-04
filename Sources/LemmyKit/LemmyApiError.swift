//
// Copyright (c) 2023-2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Errors thrown by ``LemmyApi`` calls.
///
/// Marked `@unchecked Sendable` so callers can store an instance in
/// `@Observable` view-model state. The carried `any Error` payloads are
/// not themselves `Sendable`, but in practice callers pass them around
/// as immutable terminal failure values; the conformance is a pragmatic
/// concession to that usage.
public enum LemmyApiError: Error, @unchecked Sendable {
    /// A network error has occurred.
    case network(Error)

    /// Failed to parse network response.
    case failedToDeserializeResponse(underlyingError: Error)

    /// Lemmy server returned a specified error.
    case serverError(Components.Schemas.ErrorResponse)

    /// Lemmy server returned an authorization error.
    case unauthorized(message: String?)

    /// Request to Lemmy server failed with an unexpected error.
    case unknownServerError(httpStatusCode: Int, error: Error?)

    /// An unexpected error has occurred.
    ///
    /// This is a catch-all case that should never happen, if it does we need to catch and handle errors better.
    case unknown(Error)
}
