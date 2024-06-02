//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Get list of comments for a given listing `type`.
    func getComments(
        type: Components.Schemas.ListingType,
        sort: Components.Schemas.CommentSortType? = nil,
        maxDepth: Int32? = nil,
        postID: Components.Schemas.PostID? = nil,
        parentID: Components.Schemas.CommentID? = nil,
        filter: Set<Filter>? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.GetCommentsResponse {
        let response: Operations.getComments.Output
        do {
            response = try await client.getComments(.init(query: .init(
                type_: type,
                sort: sort,
                max_depth: maxDepth,
                page: page,
                limit: limit,
                post_id: postID,
                parent_id: parentID,
                saved_only: filter?.contains(where: \.isSaved),
                liked_only: filter?.contains(where: \.isLiked),
                disliked_only: filter?.contains(where: \.isDisliked)
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
}
