//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Edits the body of an existing comment and returns the version-neutral ``CommentView``
    /// reflecting the change.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``voteCommentNeutral(id:direction:)`` shape. Both backends
    /// extract the returned `comment_view` and map it via
    /// `neutralCommentView(fromV3:)`/`neutralCommentView(fromV4:)`.
    ///
    /// Only `content` is exposed here; v3/v4's `EditComment` also accepts `language_id`, omitted
    /// as YAGNI and always sent as nil, leaving it unchanged.
    ///
    /// - Parameters:
    ///   - id: the comment to edit.
    ///   - content: the new markdown body.
    /// - Returns: the neutral `CommentView` reflecting the edit.
    /// - Note: requires authentication.
    func editCommentNeutral(id: Int64, content: String) async throws -> CommentView {
        switch apiVersion {
        case .v3:
            try await editCommentNeutralV3(id: id, content: content)
        case .v4:
            try await editCommentNeutralV4(id: id, content: content)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "editComment")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``editComment(commentID:content:languageID:)``, then maps the extracted v3 `comment_view`
    /// up to the neutral shape.
    func editCommentNeutralV3(id: Int64, content: String) async throws -> CommentView {
        let commentID = try v3CommentID(id)

        let response: Operations.editComment.Output
        do {
            response = try await client.editComment(body: .json(.init(
                comment_id: commentID,
                content: content
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

    /// v4 path: calls the v4 generated client's `EditComment` operation, then maps the extracted
    /// v4 `comment_view` near-directly to the neutral shape. v4's `EditComment` only documents
    /// the `ok` response for this operation (no `unauthorized`/`badRequest` cases like v3), so
    /// anything else falls through to `.undocumented`.
    func editCommentNeutralV4(id: Int64, content: String) async throws -> CommentView {
        let response: LemmyKitV4Generated.Operations.EditComment.Output
        do {
            response = try await v4Client.EditComment(body: .json(.init(
                content: content,
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
