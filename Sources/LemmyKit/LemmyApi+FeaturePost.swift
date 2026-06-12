//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Feature (pin) or unfeature the post `postID`.
    ///
    /// `featureType` chooses where the post is featured: `.Community` pins it
    /// to the top of its community (available to community moderators), while
    /// `.Local` pins it to the instance front page (admin-only on most
    /// instances).
    func featurePost(
        postID: Components.Schemas.PostID,
        featured: Bool,
        featureType: Components.Schemas.PostFeatureType
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.featurePost.Output
        do {
            response = try await client.featurePost(body: .json(.init(
                post_id: postID,
                featured: featured,
                feature_type: featureType
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
