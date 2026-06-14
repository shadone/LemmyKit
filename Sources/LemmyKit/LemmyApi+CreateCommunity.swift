//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a new community with the unique `name` and a human-readable `title`.
    func createCommunity(
        name: String,
        title: String,
        description: String? = nil,
        icon: String? = nil,
        banner: String? = nil,
        nsfw: Bool? = nil,
        postingRestrictedToMods: Bool? = nil,
        discussionLanguages: [Components.Schemas.LanguageID]? = nil,
        visibility: Components.Schemas.CommunityVisibility? = nil
    ) async throws -> Components.Schemas.CommunityResponse {
        let response: Operations.createCommunity.Output
        do {
            response = try await client.createCommunity(body: .json(.init(
                name: name,
                title: title,
                description: description,
                icon: icon,
                banner: banner,
                nsfw: nsfw,
                posting_restricted_to_mods: postingRestrictedToMods,
                discussion_languages: discussionLanguages,
                visibility: visibility
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
