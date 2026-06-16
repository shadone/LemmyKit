//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Vote on the post `postID` with the given `status`.
    ///
    /// - Parameters:
    ///   - postID: the post to vote on.
    ///   - status: the vote to cast: `.liked`, `.disliked`, or `.neutral` to remove an existing vote.
    /// - Note: requires authentication.
    func likePost(
        postID: Components.Schemas.PostID,
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
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
