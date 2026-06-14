//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch the moderation log, optionally filtered by moderator, community,
    /// post, comment, action type, or affected person.
    func getModlog(
        modPersonID: Components.Schemas.PersonID? = nil,
        communityID: Components.Parameters.CommunityID? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil,
        postID: Components.Parameters.PostID? = nil,
        commentID: Components.Parameters.CommentID? = nil,
        type: Components.Schemas.ModlogActionType? = nil,
        otherPersonID: Components.Schemas.PersonID? = nil
    ) async throws -> Components.Schemas.GetModlogResponse {
        let response: Operations.getModlog.Output
        do {
            response = try await client.getModlog(query: .init(
                mod_person_id: modPersonID,
                community_id: communityID,
                page: page,
                limit: limit,
                post_id: postID,
                comment_id: commentID,
                type_: type,
                other_person_id: otherPersonID
            ))
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
