//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime

public extension LemmyApi {
    /// Import a backup of the user's settings.
    ///
    /// - Parameter settings: the opaque settings object previously returned by
    ///   ``exportSettings()``, passed back verbatim.
    func importSettings(
        settings: OpenAPIRuntime.OpenAPIObjectContainer
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.importSettings.Output
        do {
            response = try await client.importSettings(body: .json(settings))
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
