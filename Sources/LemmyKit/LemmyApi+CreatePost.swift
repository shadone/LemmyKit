//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a new post in `communityID`. Requires authentication.
    ///
    /// - Parameters:
    ///   - communityID: the community to post to.
    ///   - name: the post title (required).
    ///   - url: an optional link url. For image posts, pass the uploaded
    ///     pict-rs url returned by ``uploadImage(imageData:fileName:mimeType:)``.
    ///   - body: an optional markdown body.
    ///   - nsfw: whether the post is flagged not-safe-for-work.
    func createPost(
        communityID: Components.Schemas.CommunityID,
        name: String,
        url: String?,
        body: String?,
        nsfw: Bool?
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.createPost.Output
        do {
            response = try await client.createPost(body: .json(.init(
                name: name,
                community_id: communityID,
                url: url,
                body: body,
                nsfw: nsfw
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
