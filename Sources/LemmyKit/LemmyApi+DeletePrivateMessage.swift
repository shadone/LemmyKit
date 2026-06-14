//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Delete or restore a private message.
    ///
    /// - Parameter deleted: pass `true` to delete the message, `false` to restore it.
    func deletePrivateMessage(
        privateMessageID: Components.Schemas.PrivateMessageID,
        deleted: Bool
    ) async throws -> Components.Schemas.PrivateMessageResponse {
        let response: Operations.deletePrivateMessage.Output
        do {
            response = try await client.deletePrivateMessage(body: .json(.init(
                private_message_id: privateMessageID,
                deleted: deleted
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
