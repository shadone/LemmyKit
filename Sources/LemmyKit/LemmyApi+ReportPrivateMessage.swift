//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Report a private message for moderator review.
    ///
    /// - Parameters:
    ///   - privateMessageID: the private message to report.
    ///   - reason: a short explanation of why the message is being reported.
    /// - Note: requires authentication.
    func reportPrivateMessage(
        privateMessageID: Components.Schemas.PrivateMessageID,
        reason: String
    ) async throws -> Components.Schemas.PrivateMessageReportResponse {
        let response: Operations.reportPrivateMessage.Output
        do {
            response = try await client.reportPrivateMessage(body: .json(.init(
                private_message_id: privateMessageID,
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
