//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Log in with a username or email address and password.
    ///
    /// - Parameters:
    ///   - usernameOrEmail: the account's username or email address.
    ///   - password: the account password.
    ///   - totp2faToken: the current time-based one-time (TOTP) code, required
    ///     when the account has two-factor authentication enabled; nil
    ///     otherwise. Sent to the server as `totp_2fa_token`.
    /// - Returns: a login response carrying the new session JWT.
    func login(
        usernameOrEmail: String,
        password: String,
        totp2faToken: String? = nil
    ) async throws -> Components.Schemas.LoginResponse {
        let response: Operations.login.Output
        do {
            response = try await client.login(body: .json(.init(
                username_or_email: usernameOrEmail,
                password: password,
                totp_2fa_token: totp2faToken
            )))
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
