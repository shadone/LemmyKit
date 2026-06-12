//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Distinguish (or undistinguish) the comment `commentID`.
    ///
    /// A distinguished comment is highlighted as an official moderator or
    /// admin statement.
    func distinguishComment(
        commentID: Components.Schemas.CommentID,
        distinguished: Bool
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.distinguishComment.Output
        do {
            response = try await client.distinguishComment(body: .json(.init(
                comment_id: commentID,
                distinguished: distinguished
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
