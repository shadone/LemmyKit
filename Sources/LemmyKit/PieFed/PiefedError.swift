//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// PieFed's `/api/alpha` error envelope -- observed in THREE different shapes, an inconsistency
/// confirmed live against a real PieFed instance (see the Phase-2 API probe):
///
/// 1. Most authed/validation errors: `{"code":400,"message":"incorrect_login","status":"Bad
///    Request"}` -- `status` is sometimes a human phrase, sometimes a stringified Python dict of
///    field errors.
/// 2. The spec's declared `DefaultError` shape (rarely the actual wire shape): `{"message":"..."}`
///    only.
/// 3. Stub/not-yet-implemented routes: `{"error":"not_yet_implemented"}`.
///
/// Every field is therefore `Optional` so any one of the three shapes -- or a future PieFed drop
/// of a key -- decodes without throwing. `PiefedClient`'s shared error-mapping path picks a single
/// semantic token from whichever fields are present (precedence: `message` ?? `error` ?? `status`
/// ?? `code`) and synthesizes the existing `LemmyApiError.serverError(ErrorResponse)` channel so
/// downstream consumers are unaffected by the dialect.
public struct PiefedErrorBody: Codable, Sendable {
    public let code: Int?
    public let message: String?
    public let status: String?
    /// The `{"error":"..."}` stub-route shape's sole field, e.g. `"not_yet_implemented"`.
    public let error: String?
}
