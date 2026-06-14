//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing post identified by `postID`. Only the fields you pass
    /// are changed.
    ///
    /// - Parameters:
    ///   - altText: Optional alt text, usable for image posts.
    ///   - customThumbnail: Instead of fetching a thumbnail, use a custom one.
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
