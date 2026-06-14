//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a custom emoji. Admin only.
    /// - Parameters:
    ///   - shortcode: The text used to reference the emoji, e.g. `party_blob`.
    ///   - imageURL: The URL of the emoji image.
    ///   - altText: Accessibility alt text describing the emoji.
    ///   - keywords: Search keywords associated with the emoji.
    func createCustomEmoji(
        category: Swift.String,
        shortcode: Swift.String,
        imageURL: Swift.String,
        altText: Swift.String,
        keywords: [Swift.String]
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
