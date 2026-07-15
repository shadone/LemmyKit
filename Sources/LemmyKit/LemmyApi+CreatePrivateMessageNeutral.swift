//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Sends a private message to `recipientId` and returns the version-neutral
    /// ``PrivateMessageView`` for the created message.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's
    /// `createPrivateMessage` mapped "up" via `neutralPrivateMessageView(fromV3:)`, or the v4
    /// client's `CreatePrivateMessage` mapped near-directly via
    /// `neutralPrivateMessageView(fromV4:)`. Unlike ``loginNeutral(usernameOrEmail:password:totp:)``/
    /// ``saveUserSettingsNeutral(showNSFW:blurNSFW:defaultSortType:defaultListingType:displayName:bio:showScores:showBotAccounts:showReadPosts:showAvatars:)``,
    /// this endpoint's path did not move between versions -- both are `POST
    /// /api/v{3,4}/private_message`.
    ///
    /// - Parameters:
    ///   - content: the markdown body of the message.
    ///   - recipientId: the person to send the message to.
    /// - Returns: the neutral `PrivateMessageView` for the created message.
    /// - Note: requires authentication.
    func createPrivateMessageNeutral(content: String, recipientId: Int64) async throws -> PrivateMessageView {
        switch apiVersion {
        case .v3:
            try await createPrivateMessageNeutralV3(content: content, recipientId: recipientId)
        case .v4:
            try await createPrivateMessageNeutralV4(content: content, recipientId: recipientId)
        case .piefed:
            try await createPrivateMessageNeutralPiefed(content: content, recipientId: recipientId)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``createPrivateMessage(content:recipientID:)``, then maps the extracted v3
    /// `private_message_view` up to the neutral shape.
    func createPrivateMessageNeutralV3(content: String, recipientId: Int64) async throws -> PrivateMessageView {
        let recipientID = try v3PersonID(recipientId)

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
                return neutralPrivateMessageView(fromV3: json.private_message_view)
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

    /// v4 path: calls the v4 generated client's `CreatePrivateMessage` operation, then maps the
    /// extracted v4 `private_message_view` near-directly to the neutral shape. v4's
    /// `CreatePrivateMessage` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func createPrivateMessageNeutralV4(content: String, recipientId: Int64) async throws -> PrivateMessageView {
        let response: LemmyKitV4Generated.Operations.CreatePrivateMessage.Output
        do {
            response = try await v4Client.CreatePrivateMessage(body: .json(.init(
                recipient_id: recipientId,
                content: content
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPrivateMessageView(fromV4: json.private_message_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.createPrivateMessage(content:recipientId:)` -- `POST
    /// /api/alpha/private_message`, `{content, recipient_id}`, matching the spec's
    /// `CreatePrivateMessageRequest` -- then maps the extracted `private_message_view` up to the
    /// neutral shape via `neutralPrivateMessageView(fromPiefed:)`.
    func createPrivateMessageNeutralPiefed(content: String, recipientId: Int64) async throws -> PrivateMessageView {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "createPrivateMessage") }
        let response = try await piefedClient.createPrivateMessage(content: content, recipientId: recipientId)
        return neutralPrivateMessageView(fromPiefed: response.private_message_view)
    }
}
