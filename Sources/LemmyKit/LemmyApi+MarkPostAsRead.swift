//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func markPostAsRead(
        postIds: [Components.Schemas.PostID],
        read: Bool
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.markPostAsRead.Output
        do {
            response = try await client.markPostAsRead(body: .json(.init(
                post_ids: postIds,
                read: read
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

    func markPostAsRead(
        postIds: [Components.Schemas.PostID],
        read: Bool
    ) -> AnyPublisher<Components.Schemas.SuccessResponse, LemmyApiError> {
        Future {
            try await self.markPostAsRead(
                postIds: postIds,
                read: read
            )
        }.eraseToAnyPublisher()
    }
}
