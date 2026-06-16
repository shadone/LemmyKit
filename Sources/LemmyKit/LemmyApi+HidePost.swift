//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Hide or unhide one or more posts for the logged-in account.
    ///
    /// - Parameters:
    ///   - postIDs: the posts to hide or unhide.
    ///   - hide: true to hide the posts, false to unhide them.
    /// - Note: requires authentication.
    func hidePost(
        postIDs: [Components.Schemas.PostID],
        hide: Bool
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.hidePost.Output
        do {
            response = try await client.hidePost(body: .json(.init(
                post_ids: postIDs,
                hide: hide
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
