//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Saves or unsaves a comment for the signed-in account and returns the version-neutral
    /// ``CommentView`` reflecting the new saved state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``savePostNeutral(id:saved:)`` shape: the v3 client's
    /// `saveComment` mapped "up" via `neutralCommentView(fromV3:)`, or the v4 client's
    /// `SaveComment` mapped near-directly via `neutralCommentView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the comment to save or unsave.
    ///   - saved: true to save the comment, false to unsave it.
    /// - Returns: the neutral `CommentView` reflecting the new saved state.
    /// - Note: requires authentication.
    func saveCommentNeutral(id: Int64, saved: Bool) async throws -> CommentView {
        switch apiVersion {
        case .v3:
            try await saveCommentNeutralV3(id: id, saved: saved)
        case .v4:
            try await saveCommentNeutralV4(id: id, saved: saved)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "saveComment")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``saveComment(commentID:save:)``, then maps the extracted v3 `comment_view` up to the
    /// neutral shape.
    func saveCommentNeutralV3(id: Int64, saved: Bool) async throws -> CommentView {
        let commentID = try v3CommentID(id)

        let response: Operations.saveComment.Output
        do {
            response = try await client.saveComment(body: .json(.init(
                comment_id: commentID,
                save: saved
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

    /// v4 path: calls the v4 generated client's `SaveComment` operation, then maps the extracted
    /// v4 `comment_view` near-directly to the neutral shape. v4's `SaveComment` only documents
    /// the `ok` response for this operation (no `unauthorized`/`badRequest` cases like v3), so
    /// anything else falls through to `.undocumented`.
    func saveCommentNeutralV4(id: Int64, saved: Bool) async throws -> CommentView {
        let response: LemmyKitV4Generated.Operations.SaveComment.Output
        do {
            response = try await v4Client.SaveComment(body: .json(.init(
                save: saved,
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
