//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// PieFed's `/api/alpha` error envelope, e.g. a failed login returns
/// `{"code":400,"message":"incorrect_login","status":"Bad Request"}`.
///
/// This is a different shape from Lemmy's `{"error":"..."}` envelope (`ErrorResponse`), so
/// PieFed responses need their own decode step. A later adapter maps this into the existing
/// `LemmyApiError.serverError(ErrorResponse)` channel (synthesizing `ErrorResponse(error:
/// code-or-status, message: message)`) so downstream consumers are unaffected by the dialect.
public struct PiefedErrorBody: Codable, Sendable {
    public let code: Int
    public let message: String
    public let status: String
}
