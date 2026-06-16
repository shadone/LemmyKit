//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Enable or disable two-factor authentication for the logged-in account.
    ///
    /// - Parameters:
    ///   - totpToken: the 6-digit code from the authenticator app.
    ///   - enabled: true to enable two-factor auth, false to disable it.
    /// - Note: requires authentication.
    func updateTotp(
        totpToken: String,
        enabled: Bool
    ) async throws -> Components.Schemas.UpdateTotpResponse {
        let response: Operations.updateTotp.Output
        do {
            response = try await client.updateTotp(body: .json(.init(
                totp_token: totpToken,
                enabled: enabled
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
