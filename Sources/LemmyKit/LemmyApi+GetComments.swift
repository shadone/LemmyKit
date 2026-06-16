//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

extension LemmyApi {
    /// Shared transport and response decoding for the public `getComments`
    /// overloads. Each overload builds the query for its scope and forwards
    /// here.
    func getComments(
        query: Operations.getComments.Input.Query
    ) async throws -> Components.Schemas.GetCommentsResponse {
        let response: Operations.getComments.Output
        do {
            response = try await client.getComments(.init(query: query))
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
