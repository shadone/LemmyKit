//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Get list of comments for a given post.
    func getComments(
        postID: Components.Schemas.PostID? = nil,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        let response: Operations.getComments.Output
        do {
            response = try await client.getComments(.init(query: .init(
                type_: nil,
                sort: sort,
                max_depth: maxDepth,
                page: nil,
                limit: nil,
                community_id: nil,
                community_name: nil,
                post_id: postID,
                parent_id: nil,
                saved_only: nil,
                liked_only: nil,
                disliked_only: nil
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

    @available(*, deprecated)
    func getComments(
        postID: Components.Schemas.PostID? = nil,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil
    ) -> AnyPublisher<Components.Schemas.GetCommentsResponse, LemmyApiError> {
        Future {
            try await self.getComments(
                postID: postID,
                sort: sort,
                maxDepth: maxDepth
            )
        }.eraseToAnyPublisher()
    }
}
