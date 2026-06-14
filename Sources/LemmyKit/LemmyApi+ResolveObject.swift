//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Resolve a federated object (community, person, post, or comment) by its
    /// ActivityPub URL or fully-qualified name.
    ///
    /// - Parameters:
    ///   - query: The object URL or name to resolve.
    func resolveObject(
        query: Swift.String
    ) async throws -> Components.Schemas.ResolveObjectResponse {
        let response: Operations.resolveObject.Output
        do {
            response = try await client.resolveObject(query: .init(
                q: query
            ))
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
