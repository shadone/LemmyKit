//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List post reports visible to the logged-in moderator or admin.
    ///
    /// - Parameters:
    ///   - unresolvedOnly: when true, return only reports not yet resolved.
    ///   - communityID: restrict to reports in this community; nil lists all communities.
    ///   - postID: restrict to reports for this post; nil lists all posts.
    ///   - page: 1-based page number.
    ///   - limit: maximum number of reports to return.
    /// - Note: requires moderator or admin.
    func listPostReports(
        unresolvedOnly: Components.Parameters.UnresolvedOnly? = nil,
        communityID: Components.Parameters.CommunityID? = nil,
        postID: Components.Parameters.PostID? = nil,
        page: Components.Parameters.Page? = nil,
        limit: Components.Parameters.Limit? = nil
    ) async throws -> Components.Schemas.ListPostReportsResponse {
        let response: Operations.listPostReports.Output
        do {
            response = try await client.listPostReports(query: .init(
                unresolved_only: unresolvedOnly,
                community_id: communityID,
                post_id: postID,
                page: page,
                limit: limit
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
