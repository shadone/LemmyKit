//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Send a private message to `recipientID`.
    ///
    /// - Parameters:
    ///   - content: the markdown body of the message.
    ///   - recipientID: the person to send the message to.
    /// - Returns: the created private message.
    /// - Note: requires authentication.
    func createPrivateMessage(
        content: String,
        recipientID: Components.Schemas.PersonID
    ) async throws -> Components.Schemas.PrivateMessageResponse {
        let response: Operations.createPrivateMessage.Output
        do {
            response = try await client.createPrivateMessage(body: .json(.init(
                content: content,
                recipient_id: recipientID
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
