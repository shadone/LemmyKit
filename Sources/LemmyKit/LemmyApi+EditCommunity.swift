//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing community identified by `communityID`. Pass `visibility`
    /// to change whether the community is public or local-only.
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
