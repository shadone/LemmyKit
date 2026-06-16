//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a new post in `communityID`.
    ///
    /// - Parameters:
    ///   - communityID: the community to post in.
    ///   - name: the post title.
    ///   - url: optional link url; for image posts pass the pict-rs url from ``uploadImage(imageData:fileName:mimeType:)``.
    ///   - body: optional markdown body.
    ///   - nsfw: whether to flag the post not-safe-for-work.
    ///   - altText: optional alt text describing the linked image, for accessibility.
    ///   - customThumbnail: optional custom thumbnail url overriding the auto-generated one; pass an uploaded pict-rs url.
    /// - Returns: the created post, including its new server id.
    /// - Note: requires authentication.
    func createPost(
        communityID: Components.Schemas.CommunityID,
        name: String,
        url: String? = nil,
        body: String? = nil,
        nsfw: Bool? = nil,
        altText: String? = nil,
        customThumbnail: String? = nil
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.createPost.Output
        do {
            response = try await client.createPost(body: .json(.init(
                name: name,
                community_id: communityID,
                url: url,
                body: body,
                alt_text: altText,
                nsfw: nsfw,
                custom_thumbnail: customThumbnail
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
