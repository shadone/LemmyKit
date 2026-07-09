//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Deletes or restores a comment owned by the signed-in account and returns the
    /// version-neutral ``CommentView`` reflecting the new deleted state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``voteCommentNeutral(id:direction:)`` shape: both backends'
    /// `DeleteComment` request shapes agree (`comment_id`, `deleted`), so only the id narrowing
    /// and the mapping direction differ. Both extract the returned `comment_view` and map it via
    /// `neutralCommentView(fromV3:)`/`neutralCommentView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the comment to delete or restore.
    ///   - deleted: true to delete the comment, false to restore it.
    /// - Returns: the neutral `CommentView` reflecting the new deleted state.
    /// - Note: requires authentication.
    func deleteCommentNeutral(id: Int64, deleted: Bool) async throws -> CommentView {
        switch apiVersion {
        case .v3:
            try await deleteCommentNeutralV3(id: id, deleted: deleted)
        case .v4:
            try await deleteCommentNeutralV4(id: id, deleted: deleted)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``deleteComment(commentID:deleted:)``, then maps the extracted v3 `comment_view` up to
    /// the neutral shape.
    func deleteCommentNeutralV3(id: Int64, deleted: Bool) async throws -> CommentView {
        let commentID = try v3CommentID(id)

        let response: Operations.deleteComment.Output
        do {
            response = try await client.deleteComment(body: .json(.init(
                comment_id: commentID,
                deleted: deleted
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralCommentView(fromV3: json.comment_view)
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

    /// v4 path: calls the v4 generated client's `DeleteComment` operation, then maps the
    /// extracted v4 `comment_view` near-directly to the neutral shape. v4's `DeleteComment` only
    /// documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases like
    /// v3), so anything else falls through to `.undocumented`.
    func deleteCommentNeutralV4(id: Int64, deleted: Bool) async throws -> CommentView {
        let response: LemmyKitV4Generated.Operations.DeleteComment.Output
        do {
            response = try await v4Client.DeleteComment(body: .json(.init(
                deleted: deleted,
                comment_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralCommentView(fromV4: json.comment_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
