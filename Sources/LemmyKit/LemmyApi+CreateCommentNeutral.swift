//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Creates a new comment and returns the version-neutral ``CommentView`` for it.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``voteCommentNeutral(id:direction:)`` shape: the v3
    /// client's `createComment` narrows `postId`/`parentId`/`languageId` down to v3's
    /// `Int32`-backed ids, while the v4 client's `CreateComment` takes them as-is (v4's
    /// `PostId`/`CommentId`/`LanguageId` are already `Int64`). Both extract the returned
    /// `comment_view` and map it via `neutralCommentView(fromV3:)`/`neutralCommentView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - content: the markdown body of the comment.
    ///   - postId: the post to comment on.
    ///   - parentId: the comment to reply to; nil to reply to the post itself.
    ///   - languageId: language of the comment content; nil lets the server pick a default.
    /// - Returns: the neutral `CommentView` for the newly created comment.
    /// - Note: requires authentication.
    func createCommentNeutral(
        content: String,
        postId: Int64,
        parentId: Int64?,
        languageId: Int64?
    ) async throws -> CommentView {
        switch apiVersion {
        case .v3:
            try await createCommentNeutralV3(
                content: content,
                postId: postId,
                parentId: parentId,
                languageId: languageId
            )
        case .v4:
            try await createCommentNeutralV4(
                content: content,
                postId: postId,
                parentId: parentId,
                languageId: languageId
            )
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "createComment")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``createComment(postID:content:parentID:)``, narrowing `postId`/`parentId`/`languageId`
    /// down to v3's `Int32`-backed ids, then maps the extracted v3 `comment_view` up to the
    /// neutral shape.
    func createCommentNeutralV3(
        content: String,
        postId: Int64,
        parentId: Int64?,
        languageId: Int64?
    ) async throws -> CommentView {
        let postID = try v3PostID(postId)
        let parentID = try parentId.map(v3CommentID)
        let languageID = try languageId.map(v3LanguageID)

        let response: Operations.createComment.Output
        do {
            response = try await client.createComment(body: .json(.init(
                content: content,
                post_id: postID,
                parent_id: parentID,
                language_id: languageID
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

    /// v4 path: calls the v4 generated client's `CreateComment` operation, passing
    /// `postId`/`parentId`/`languageId` through unchanged (v4's `PostId`/`CommentId`/`LanguageId`
    /// are already `Int64`), then maps the extracted v4 `comment_view` near-directly to the
    /// neutral shape. v4's `CreateComment` only documents the `ok` response for this operation
    /// (no `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func createCommentNeutralV4(
        content: String,
        postId: Int64,
        parentId: Int64?,
        languageId: Int64?
    ) async throws -> CommentView {
        let response: LemmyKitV4Generated.Operations.CreateComment.Output
        do {
            response = try await v4Client.CreateComment(body: .json(.init(
                language_id: languageId,
                parent_id: parentId,
                post_id: postId,
                content: content
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
