//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Update the comment like status to be as specified by `status`.
    func likeComment(
        _ commentID: Components.Schemas.CommentID,
        status: LikeStatus
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.likeComment.Output
        do {
            response = try await client.likeComment(body: .json(.init(
                comment_id: commentID,
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
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// Update the comment like status to be as specified by `status`.
    @available(*, deprecated)
    func likeComment(
        _ commentID: Components.Schemas.CommentID,
        status: LikeStatus
    ) -> AnyPublisher<Components.Schemas.CommentResponse, LemmyApiError> {
        Future {
            try await self.likeComment(commentID, status: status)
        }.eraseToAnyPublisher()
    }
}
