//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Register a new user account on the backing instance.
    ///
    /// On success the response carries either a `jwt` (account ready to use) or
    /// `registration_created` / `verify_email_sent` flags describing a pending
    /// state (admin approval and/or email verification required before the
    /// account can log in). Captcha (`captchaUuid` / `captchaAnswer`) and the
    /// application `answer` are optional and only required when the instance
    /// enables them.
    func register(
        username: String,
        password: String,
        passwordVerify: String,
        email: String? = nil,
        showNsfw: Bool? = nil,
        captchaUuid: String? = nil,
        captchaAnswer: String? = nil,
        answer: String? = nil,
        honeypot: String? = nil
    ) async throws -> Components.Schemas.LoginResponse {
        let response: Operations.register.Output
        do {
            response = try await client.register(.init(body: .json(.init(
                username: username,
                password: password,
                password_verify: passwordVerify,
                show_nsfw: showNsfw,
                email: email,
                captcha_uuid: captchaUuid,
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
                return json
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
}
