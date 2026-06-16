//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Mark all inbox replies and mentions as read; private messages are not affected.
    ///
    /// - Note: requires authentication.
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

    /// Mark a comment reply as read or unread.
    ///
    /// - Parameters:
    ///   - commentReplyID: the comment reply to update.
    ///   - read: true to mark as read, false to mark as unread.
    /// - Note: requires authentication.
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

    /// Mark a person mention as read or unread.
    ///
    /// - Parameters:
    ///   - personMentionID: the person mention to update.
    ///   - read: true to mark as read, false to mark as unread.
    /// - Note: requires authentication.
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

    /// Mark a private message as read or unread.
    ///
    /// - Parameters:
    ///   - privateMessageID: the private message to update.
    ///   - read: true to mark as read, false to mark as unread.
    /// - Note: requires authentication.
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
