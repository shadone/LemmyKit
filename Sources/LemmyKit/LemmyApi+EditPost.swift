//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing post identified by `postID`.
    ///
    /// Only the fields you pass are changed; omitted parameters leave the existing values intact.
    ///
    /// - Parameters:
    ///   - postID: the post to edit.
    ///   - name: new post title; nil leaves the existing title unchanged.
    ///   - url: new link url; nil leaves the existing url unchanged.
    ///   - body: new markdown body; nil leaves the existing body unchanged.
    ///   - altText: alt text describing the linked image; nil leaves the existing value unchanged.
    ///   - nsfw: whether to flag the post not-safe-for-work; nil leaves the existing flag unchanged.
    ///   - languageID: language of the post content; nil leaves the existing language unchanged.
    ///   - customThumbnail: custom thumbnail url overriding the auto-generated one; nil leaves the existing thumbnail unchanged.
    /// - Note: requires authentication.
    func editPost(
        postID: Components.Schemas.PostID,
        name: String? = nil,
        url: String? = nil,
        body: String? = nil,
        altText: String? = nil,
        nsfw: Bool? = nil,
        languageID: Components.Schemas.LanguageID? = nil,
        customThumbnail: String? = nil
    ) async throws -> Components.Schemas.PostResponse {
        let response: Operations.editPost.Output
        do {
            response = try await client.editPost(body: .json(.init(
                post_id: postID,
                name: name,
                url: url,
                body: body,
                alt_text: altText,
                nsfw: nsfw,
                language_id: languageID,
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
