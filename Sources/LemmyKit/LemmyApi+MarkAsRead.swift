//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Mark all replies and mentions as read. Requires authentication. Note
    /// that Lemmy's `markAllAsRead` does not cover private messages.
    @discardableResult
    func markAllAsRead() async throws -> Components.Schemas.GetRepliesResponse {
        let response: Operations.markAllAsRead.Output
        do {
            response = try await client.markAllAsRead()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
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

    /// Mark a single comment reply as read/unread. Requires authentication.
    @discardableResult
    func markCommentReplyAsRead(
        commentReplyID: Components.Schemas.CommentReplyID,
        read: Bool
    ) async throws -> Components.Schemas.CommentReplyResponse {
        let response: Operations.markCommentReplyAsRead.Output
        do {
            response = try await client.markCommentReplyAsRead(body: .json(.init(
                comment_reply_id: commentReplyID,
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

    /// Mark a single person mention as read/unread. Requires authentication.
    @discardableResult
    func markPersonMentionAsRead(
        personMentionID: Components.Schemas.PersonMentionID,
        read: Bool
    ) async throws -> Components.Schemas.PersonMentionResponse {
        let response: Operations.markPersonMentionAsRead.Output
        do {
            response = try await client.markPersonMentionAsRead(body: .json(.init(
                person_mention_id: personMentionID,
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

    /// Mark a single private message as read/unread. Requires authentication.
    @discardableResult
    func markPrivateMessageAsRead(
        privateMessageID: Components.Schemas.PrivateMessageID,
        read: Bool
    ) async throws -> Components.Schemas.PrivateMessageResponse {
        let response: Operations.markPrivateMessageAsRead.Output
        do {
            response = try await client.markPrivateMessageAsRead(body: .json(.init(
                private_message_id: privateMessageID,
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
