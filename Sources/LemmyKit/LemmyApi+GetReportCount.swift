//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch the number of open reports for the logged-in moderator or admin.
    /// - Parameters:
    ///   - communityID: Restrict the count to reports in the given community.
    func getReportCount(
        communityID: Components.Parameters.CommunityID? = nil
    ) async throws -> Components.Schemas.GetReportCountResponse {
        let response: Operations.getReportCount.Output
        do {
            response = try await client.getReportCount(query: .init(
                community_id: communityID
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
