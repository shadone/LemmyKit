//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing community's settings.
    ///
    /// - Parameters:
    ///   - communityID: the community to edit.
    ///   - title: new human-readable display title; nil leaves it unchanged.
    ///   - description: new markdown sidebar description; nil leaves it unchanged.
    ///   - icon: url of the community's icon image; nil leaves it unchanged.
    ///   - banner: url of the community's banner image; nil leaves it unchanged.
    ///   - nsfw: true to mark the community as NSFW, false to unmark it; nil leaves it unchanged.
    ///   - postingRestrictedToMods: true to allow only moderators to create posts; nil leaves it unchanged.
    ///   - discussionLanguages: replacement list of accepted language ids; nil leaves it unchanged.
    ///   - visibility: who can see and find the community; nil leaves it unchanged.
    /// - Note: requires authentication as a moderator or admin.
    func editCommunity(
        communityID: Components.Schemas.CommunityID,
        title: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        banner: String? = nil,
        nsfw: Bool? = nil,
        postingRestrictedToMods: Bool? = nil,
        discussionLanguages: [Components.Schemas.LanguageID]? = nil,
        visibility: Components.Schemas.CommunityVisibility? = nil
    ) async throws -> Components.Schemas.CommunityResponse {
        let response: Operations.editCommunity.Output
        do {
            response = try await client.editCommunity(body: .json(.init(
                community_id: communityID,
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
