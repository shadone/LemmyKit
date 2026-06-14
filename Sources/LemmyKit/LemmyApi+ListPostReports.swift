//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// List post reports visible to the logged-in moderator or admin.
    /// - Parameters:
    ///   - unresolvedOnly: When `true`, return only reports that have not yet been resolved.
    ///   - communityID: Restrict results to reports in the given community.
    ///   - postID: Restrict results to reports for the given post.
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
