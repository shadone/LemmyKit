//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Change the logged-in account's password. Returns a fresh login response
    /// (the existing session may be invalidated, so use the returned token).
    func changePassword(
        newPassword: String,
        newPasswordVerify: String,
        oldPassword: String
    ) async throws -> Components.Schemas.LoginResponse {
        let response: Operations.changePassword.Output
        do {
            response = try await client.changePassword(body: .json(.init(
                new_password: newPassword,
                new_password_verify: newPasswordVerify,
                old_password: oldPassword
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
