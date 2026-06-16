//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Set a new password using the token delivered in a password-reset email.
    ///
    /// - Parameters:
    ///   - token: the reset token delivered by email.
    ///   - password: the desired new password.
    ///   - passwordVerify: repeat of `password` for confirmation.
    func passwordChangeAfterReset(
        token: String,
        password: String,
        passwordVerify: String
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.passwordChangeAfterReset.Output
        do {
            response = try await client.passwordChangeAfterReset(body: .json(.init(
                token: token,
                password: password,
                password_verify: passwordVerify
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
