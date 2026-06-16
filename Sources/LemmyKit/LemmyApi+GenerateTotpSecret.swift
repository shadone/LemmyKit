//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Generate a new TOTP secret for the logged-in account.
    ///
    /// - Returns: the new TOTP secret and provisioning URI; confirm by calling ``updateTotp(totpToken:enabled:)`` with a valid token.
    /// - Note: requires authentication.
    func generateTotpSecret() async throws -> Components.Schemas.GenerateTotpSecretResponse {
        let response: Operations.generateTotpSecret.Output
        do {
            response = try await client.generateTotpSecret()
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
