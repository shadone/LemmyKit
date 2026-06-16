//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime

public extension LemmyApi {
    /// Export a backup of the current user's settings, including saved content, followed communities, and blocks.
    ///
    /// - Returns: an opaque settings blob; pass it verbatim to ``importSettings(settings:)`` to restore.
    /// - Note: requires authentication.
    func exportSettings() async throws -> OpenAPIRuntime.OpenAPIObjectContainer {
        let response: Operations.exportSettings.Output
        do {
            response = try await client.exportSettings()
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
