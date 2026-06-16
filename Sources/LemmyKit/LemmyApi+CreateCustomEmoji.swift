//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a custom emoji.
    ///
    /// - Parameters:
    ///   - category: the emoji category to group it under.
    ///   - shortcode: the emoji shortcode (without colons).
    ///   - imageURL: the url of the emoji image.
    ///   - altText: alt text describing the emoji, for accessibility.
    ///   - keywords: searchable keywords for the emoji.
    /// - Note: admin only.
    func createCustomEmoji(
        category: String,
        shortcode: String,
        imageURL: String,
        altText: String,
        keywords: [String]
    ) async throws -> Components.Schemas.CustomEmojiResponse {
        let response: Operations.createCustomEmoji.Output
        do {
            response = try await client.createCustomEmoji(body: .json(.init(
                category: category,
                shortcode: shortcode,
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
