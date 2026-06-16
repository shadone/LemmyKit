//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List the votes (likes) on the post identified by `postID`.
    ///
    /// - Parameters:
    ///   - postID: the post whose votes to list.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of votes to return.
    /// - Note: admin only.
    func listPostLikes(
        postID: Components.Schemas.PostID,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.ListPostLikesResponse {
        let response: Operations.listPostLikes.Output
        do {
            response = try await client.listPostLikes(query: .init(
                post_id: postID,
                page: page,
                limit: limit
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
