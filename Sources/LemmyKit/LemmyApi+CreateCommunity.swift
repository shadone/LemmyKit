//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create a new community.
    ///
    /// - Parameters:
    ///   - name: the community's url-safe actor name (cannot be changed later).
    ///   - title: the human-readable display title.
    ///   - description: optional markdown sidebar description.
    ///   - icon: url of the community's icon image.
    ///   - banner: url of the community's banner image.
    ///   - nsfw: true to mark the community as NSFW.
    ///   - postingRestrictedToMods: true to allow only moderators to create posts.
    ///   - discussionLanguages: language ids the community accepts; nil for no restriction.
    ///   - visibility: who can see and find the community; nil uses the server default.
    /// - Returns: the created community.
    /// - Note: requires authentication.
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
