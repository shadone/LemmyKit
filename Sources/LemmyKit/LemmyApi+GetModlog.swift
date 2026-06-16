//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch the moderation log, optionally filtered by moderator, community,
    /// post, comment, action type, or affected person.
    ///
    /// - Parameters:
    ///   - modPersonID: restrict results to actions taken by this moderator; nil lists all.
    ///   - communityID: restrict results to actions in this community; nil lists all.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of results to return.
    ///   - postID: restrict results to actions affecting this post; nil lists all.
    ///   - commentID: restrict results to actions affecting this comment; nil lists all.
    ///   - type: which kind of modlog action to return; nil returns all action types.
    ///   - otherPersonID: restrict results to actions that affected this person; nil lists all.
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
