//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Update the post like status to be as specified by `status`.
    func likePost(
        _ postID: Components.Schemas.PostID,
        status: LikeStatus
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.likePost.Output
        do {
            response = try await client.likePost(body: .json(.init(
                post_id: postID,
                score: status.rawValue
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

    /// Update the post like status to be as specified by `status`.
    @available(*, deprecated)
    func likePost(
        _ postID: Components.Schemas.PostID,
        status: LikeStatus
    ) -> AnyPublisher<Components.Schemas.PostResponse, LemmyApiError> {
        Future {
            try await self.likePost(postID, status: status)
        }.eraseToAnyPublisher()
    }
}
