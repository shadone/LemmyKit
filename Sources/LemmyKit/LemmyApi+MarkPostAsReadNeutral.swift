//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Marks a post as read or unread for the signed-in account.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). The two backends disagree on request shape, the same "array vs scalar"
    /// split as ``hidePostNeutral(id:hidden:)``: v3's `MarkPostAsRead` request carries an *array*
    /// of post ids (`post_ids`), even though this call only ever marks one, so the v3 path wraps
    /// `id` in a single-element array; v4's `MarkPostAsRead` request instead takes a single
    /// scalar `post_id`. On the response side v3's `markPostAsRead` returns a bare
    /// `SuccessResponse`, while v4's `MarkPostAsRead` returns a full `PostResponse` -- like
    /// `hidePostNeutral(id:hidden:)`, this method reports success by not throwing, so either
    /// response body is discarded once the `.ok` case is confirmed.
    ///
    /// - Parameters:
    ///   - id: the post to mark as read or unread.
    ///   - read: true to mark the post as read, false to mark it as unread.
    /// - Note: requires authentication.
    func markPostAsReadNeutral(id: Int64, read: Bool) async throws {
        switch apiVersion {
        case .v3:
            try await markPostAsReadNeutralV3(id: id, read: read)
        case .v4:
            try await markPostAsReadNeutralV4(id: id, read: read)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "markPostAsRead")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``markPostAsRead(postIDs:read:)``, wrapping the single `id` in the array v3's
    /// `MarkPostAsRead` request requires.
    func markPostAsReadNeutralV3(id: Int64, read: Bool) async throws {
        let postID = try v3PostID(id)

        let response: Operations.markPostAsRead.Output
        do {
            response = try await client.markPostAsRead(body: .json(.init(
                post_ids: [postID],
                read: read
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

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

    /// v4 path: calls the v4 generated client's `MarkPostAsRead` operation with a scalar
    /// `post_id`. Unlike v3, v4's `MarkPostAsRead` returns a `PostResponse` (not a
    /// `SuccessResponse`); its body is discarded here since this method reports success by not
    /// throwing. v4's `MarkPostAsRead` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func markPostAsReadNeutralV4(id: Int64, read: Bool) async throws {
        let response: LemmyKitV4Generated.Operations.MarkPostAsRead.Output
        do {
            response = try await v4Client.MarkPostAsRead(body: .json(.init(
                read: read,
                post_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
