//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Report the post `postID` on behalf of the logged-in account.
    ///
    /// - Parameters:
    ///   - postID: the post to report.
    ///   - reason: the reason for the report.
    /// - Note: requires authentication.
    func createPostReport(
        postID: Components.Schemas.PostID,
        reason: String
    ) async throws -> Components.Schemas.PostReportResponse {
        let response: Operations.reportPost.Output
        do {
            response = try await client.reportPost(body: .json(.init(
                post_id: postID,
                reason: reason
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
