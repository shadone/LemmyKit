//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Submit a report on a comment on behalf of the logged-in account.
    ///
    /// - Parameters:
    ///   - commentID: the comment to report.
    ///   - reason: the reason for the report, shown to moderators.
    /// - Note: requires authentication.
    func createCommentReport(
        commentID: Components.Schemas.CommentID,
        reason: String
    ) async throws -> Components.Schemas.CommentReportResponse {
        let response: Operations.reportComment.Output
        do {
            response = try await client.reportComment(body: .json(.init(
                comment_id: commentID,
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
