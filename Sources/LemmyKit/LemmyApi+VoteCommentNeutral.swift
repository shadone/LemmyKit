//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Casts or retracts the signed-in account's vote on a comment and returns the
    /// version-neutral ``CommentView`` reflecting the new vote state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``votePostNeutral(id:direction:)`` shape: the v3 client's
    /// `likeComment` writes `direction`'s signed ``VoteDirection/v3Score``, while the v4 client's
    /// `LikeComment` writes `direction`'s optional ``VoteDirection/v4IsUpvote``. Both extract the
    /// returned `comment_view` and map it via
    /// `neutralCommentView(fromV3:)`/`neutralCommentView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the comment to vote on.
    ///   - direction: the vote to cast: `.up`, `.down`, or `.none` to retract an existing vote.
    /// - Returns: the neutral `CommentView` reflecting the new vote state.
    /// - Note: requires authentication.
    func voteCommentNeutral(id: Int64, direction: VoteDirection) async throws -> CommentView {
        switch apiVersion {
        case .v3:
            try await voteCommentNeutralV3(id: id, direction: direction)
        case .v4:
            try await voteCommentNeutralV4(id: id, direction: direction)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "voteComment")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``likeComment(commentID:status:)``, writing `direction.v3Score` directly instead of
    /// routing through `LikeStatus`, then maps the extracted v3 `comment_view` up to the neutral
    /// shape.
    func voteCommentNeutralV3(id: Int64, direction: VoteDirection) async throws -> CommentView {
        let commentID = try v3CommentID(id)

        let response: Operations.likeComment.Output
        do {
            response = try await client.likeComment(body: .json(.init(
                comment_id: commentID,
                score: Components.Schemas.MyVote(direction.v3Score)
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

    /// v4 path: calls the v4 generated client's `LikeComment` operation writing
    /// `direction.v4IsUpvote`, then maps the extracted v4 `comment_view` near-directly to the
    /// neutral shape. v4's `LikeComment` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func voteCommentNeutralV4(id: Int64, direction: VoteDirection) async throws -> CommentView {
        let response: LemmyKitV4Generated.Operations.LikeComment.Output
        do {
            response = try await v4Client.LikeComment(body: .json(.init(
                is_upvote: direction.v4IsUpvote,
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
