//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing custom emoji. Admin only.
    /// - Parameters:
    ///   - imageURL: The URL of the emoji image.
    ///   - altText: Accessibility alt text describing the emoji.
    ///   - keywords: Search keywords associated with the emoji.
    func editCustomEmoji(
        id: Components.Schemas.CustomEmojiID,
        category: String,
        imageURL: String,
        altText: String,
        keywords: [String]
    ) async throws -> Components.Schemas.CustomEmojiResponse {
        let response: Operations.editCustomEmoji.Output
        do {
            response = try await client.editCustomEmoji(body: .json(.init(
                id: id,
                category: category,
                image_url: imageURL,
                alt_text: altText,
                keywords: keywords
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
