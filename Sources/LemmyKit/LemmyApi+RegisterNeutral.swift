//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Registers a new account on the instance and returns the session JWT, or nil if the
    /// account is pending (admin approval and/or email verification required before the account
    /// can log in).
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). Both versions share the same request/response field names -- the only
    /// difference is the wire path: v3 is `POST /api/v3/user/register`, v4 moved auth under a
    /// dedicated `/api/v4/account/auth/register`. Kept minimal, mirroring
    /// ``register(username:password:passwordVerify:email:showNSFW:captchaUUID:captchaAnswer:answer:honeypot:)``'s
    /// parameter set; v4's `Register` additionally accepts `token`/`stay_logged_in`, neither of
    /// which is part of the neutral surface yet.
    ///
    /// - Parameters:
    ///   - username: the desired username for the new account.
    ///   - password: the desired account password.
    ///   - passwordVerify: repeat of `password` for confirmation.
    ///   - email: optional email address; required on instances that mandate email verification.
    ///   - showNSFW: whether to display NSFW content; when nil, the server's default applies.
    ///   - captchaUUID: the UUID identifying the captcha challenge, when the instance requires one.
    ///   - captchaAnswer: the captcha answer text, when the instance requires one.
    ///   - answer: the application question answer, when the instance requires one.
    ///   - honeypot: anti-spam honeypot field; should be left nil by legitimate clients.
    /// - Returns: the new session JWT, or nil when the account is pending admin approval and/or
    ///   email verification.
    func registerNeutral(
        username: String,
        password: String,
        passwordVerify: String,
        email: String? = nil,
        showNSFW: Bool? = nil,
        captchaUUID: String? = nil,
        captchaAnswer: String? = nil,
        answer: String? = nil,
        honeypot: String? = nil
    ) async throws -> String? {
        switch apiVersion {
        case .v3:
            try await registerNeutralV3(
                username: username,
                password: password,
                passwordVerify: passwordVerify,
                email: email,
                showNSFW: showNSFW,
                captchaUUID: captchaUUID,
                captchaAnswer: captchaAnswer,
                answer: answer,
                honeypot: honeypot
            )
        case .v4:
            try await registerNeutralV4(
                username: username,
                password: password,
                passwordVerify: passwordVerify,
                email: email,
                showNSFW: showNSFW,
                captchaUUID: captchaUUID,
                captchaAnswer: captchaAnswer,
                answer: answer,
                honeypot: honeypot
            )
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``register(username:password:passwordVerify:email:showNSFW:captchaUUID:captchaAnswer:answer:honeypot:)``
    /// (`POST /api/v3/user/register`), then extracts `jwt` from the returned `LoginResponse`.
    func registerNeutralV3(
        username: String,
        password: String,
        passwordVerify: String,
        email: String?,
        showNSFW: Bool?,
        captchaUUID: String?,
        captchaAnswer: String?,
        answer: String?,
        honeypot: String?
    ) async throws -> String? {
        let response: Operations.register.Output
        do {
            response = try await client.register(.init(body: .json(.init(
                username: username,
                password: password,
                password_verify: passwordVerify,
                show_nsfw: showNSFW,
                email: email,
                captcha_uuid: captchaUUID,
                captcha_answer: captchaAnswer,
                honeypot: honeypot,
                answer: answer
            ))))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json.jwt
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

    /// v4 path: calls the v4 generated client's `Register` operation (`POST
    /// /api/v4/account/auth/register`, moved off v3's `/api/v3/user/register`), then extracts
    /// `jwt` from the returned `LoginResponse`. v4's `Register` only documents the `ok` response
    /// for this operation (no `unauthorized`/`badRequest` cases like v3), so anything else falls
    /// through to `.undocumented`.
    func registerNeutralV4(
        username: String,
        password: String,
        passwordVerify: String,
        email: String?,
        showNSFW: Bool?,
        captchaUUID: String?,
        captchaAnswer: String?,
        answer: String?,
        honeypot: String?
    ) async throws -> String? {
        let response: LemmyKitV4Generated.Operations.Register.Output
        do {
            response = try await v4Client.Register(body: .json(.init(
                answer: answer,
                honeypot: honeypot,
                captcha_answer: captchaAnswer,
                captcha_uuid: captchaUUID,
                email: email,
                show_nsfw: showNSFW,
                password_verify: passwordVerify,
                password: password,
                username: username
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json.jwt
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
