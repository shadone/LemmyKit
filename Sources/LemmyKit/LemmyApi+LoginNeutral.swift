//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// `loginNeutral(usernameOrEmail:password:totp:)`'s 200-response carried no `jwt`.
///
/// Lemmy's shared `LoginResponse` schema also covers registration (where a pending
/// `registration_created`/`verify_email_sent` state legitimately has no `jwt` yet -- see
/// ``LemmyApi/registerNeutral(username:password:passwordVerify:email:showNSFW:captchaUUID:captchaAnswer:answer:honeypot:)``),
/// but a genuine *login* against an existing account should always come back with one; seeing
/// neither here means the server did something unexpected, not that the account is pending.
enum LoginNeutralError: Error, Equatable {
    /// The response carried no `jwt`; `registrationCreated`/`verifyEmailSent` are the response's
    /// own pending-state flags, carried along for diagnostics.
    case missingJWT(registrationCreated: Bool, verifyEmailSent: Bool)
}

public extension LemmyApi {
    /// Logs into an existing account and returns the new session JWT.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). Both versions share the same request/response field names
    /// (`username_or_email`/`password`/`totp_2fa_token` in, `jwt` out) -- the only difference is
    /// the wire path: v3 is `POST /api/v3/user/login`, v4 moved auth under a dedicated
    /// `/api/v4/account/auth/login`. Both generated clients otherwise use identical response
    /// shapes for this call.
    ///
    /// - Parameters:
    ///   - usernameOrEmail: the account's username or email address.
    ///   - password: the account password.
    ///   - totp: the current time-based one-time (TOTP) code, required when the account has
    ///     two-factor authentication enabled; nil otherwise. Sent as `totp_2fa_token`.
    /// - Returns: the new session JWT.
    /// - Throws: ``LemmyApiError/unauthorized(message:)`` for incorrect credentials, or
    ///   ``LemmyApiError/unknown(_:)`` wrapping ``LoginNeutralError/missingJWT(registrationCreated:verifyEmailSent:)``
    ///   if the server's 200 response carried no `jwt`.
    func loginNeutral(usernameOrEmail: String, password: String, totp: String? = nil) async throws -> String {
        switch apiVersion {
        case .v3:
            try await loginNeutralV3(usernameOrEmail: usernameOrEmail, password: password, totp: totp)
        case .v4:
            try await loginNeutralV4(usernameOrEmail: usernameOrEmail, password: password, totp: totp)
        case .piefed:
            try await loginNeutralPiefed(usernameOrEmail: usernameOrEmail, password: password, totp: totp)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``login(usernameOrEmail:password:totp2faToken:)`` (`POST /api/v3/user/login`), then
    /// extracts `jwt` from the returned `LoginResponse`.
    func loginNeutralV3(usernameOrEmail: String, password: String, totp: String?) async throws -> String {
        let response: Operations.login.Output
        do {
            response = try await client.login(body: .json(.init(
                username_or_email: usernameOrEmail,
                password: password,
                totp_2fa_token: totp
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                guard let jwt = json.jwt else {
                    throw LemmyApiError.unknown(LoginNeutralError.missingJWT(
                        registrationCreated: json.registration_created,
                        verifyEmailSent: json.verify_email_sent
                    ))
                }
                return jwt
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 path: calls the v4 generated client's `Login` operation (`POST
    /// /api/v4/account/auth/login`, moved off v3's `/api/v3/user/login`), then extracts `jwt`
    /// from the returned `LoginResponse`. v4's `Login` only documents the `ok` response for this
    /// operation (no `unauthorized`/`badRequest` cases like v3), so anything else falls through
    /// to `.undocumented`.
    func loginNeutralV4(usernameOrEmail: String, password: String, totp: String?) async throws -> String {
        let response: LemmyKitV4Generated.Operations.Login.Output
        do {
            response = try await v4Client.Login(body: .json(.init(
                totp_2fa_token: totp,
                password: password,
                username_or_email: usernameOrEmail
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                guard let jwt = json.jwt else {
                    throw LemmyApiError.unknown(LoginNeutralError.missingJWT(
                        registrationCreated: json.registration_created,
                        verifyEmailSent: json.verify_email_sent
                    ))
                }
                return jwt
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.login(username:password:)`, passing `usernameOrEmail`
    /// straight through as PieFed's `username` wire field -- PieFed logs in by username only, with
    /// no email-login option (unlike v3/v4's `username_or_email`). `totp` is silently ignored: the
    /// PieFed login route has no wire field for a TOTP code at all, so a PieFed test/validation
    /// account must have two-factor authentication disabled -- there is nowhere on the wire to
    /// carry the code even if one is supplied.
    func loginNeutralPiefed(usernameOrEmail: String, password: String, totp _: String?) async throws -> String {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "login") }
        let response = try await piefedClient.login(username: usernameOrEmail, password: password)
        return response.jwt
    }
}
