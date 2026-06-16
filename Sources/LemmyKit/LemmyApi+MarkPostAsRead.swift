//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Mark one or more posts as read or unread for the logged-in account.
    ///
    /// - Parameters:
    ///   - postIDs: the posts to mark as read or unread.
    ///   - read: true to mark the posts as read, false to mark them as unread.
    /// - Note: requires authentication.
    func markPostAsRead(
        postIDs: [Components.Schemas.PostID],
        read: Bool
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.markPostAsRead.Output
        do {
            response = try await client.markPostAsRead(body: .json(.init(
                post_ids: postIDs,
                read: read
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
