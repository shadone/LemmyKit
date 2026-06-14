//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit an existing comment identified by `commentID`.
    func editComment(
        commentID: Components.Schemas.CommentID,
        content: String? = nil,
        languageID: Components.Schemas.LanguageID? = nil
    ) async throws -> Components.Schemas.CommentResponse {
        let response: Operations.editComment.Output
        do {
            response = try await client.editComment(body: .json(.init(
                comment_id: commentID,
                content: content,
                language_id: languageID
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
