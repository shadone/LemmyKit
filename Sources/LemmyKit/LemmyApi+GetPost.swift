//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Fetch a post by its id.
    func getPost(
        id: Components.Schemas.PostID
    ) async throws -> Components.Schemas.GetPostResponse {
        let response: Operations.getPost.Output
        do {
            response = try await client.getPost(.init(query: .init(
                id: id
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
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode)
        }
    }

    /// Fetch a post by its id.
    @available(*, deprecated)
    func getPost(
        id: Components.Schemas.PostID
    ) -> AnyPublisher<Components.Schemas.GetPostResponse, LemmyApiError> {
        Future {
            try await self.getPost(id: id)
        }.eraseToAnyPublisher()
    }
}
