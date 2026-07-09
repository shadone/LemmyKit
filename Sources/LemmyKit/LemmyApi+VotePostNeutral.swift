//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Casts or retracts the signed-in account's vote on a post and returns the version-neutral
    /// ``PostView`` reflecting the new vote state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's `likePost`
    /// writes `direction`'s signed ``VoteDirection/v3Score``, while the v4 client's `LikePost`
    /// writes `direction`'s optional ``VoteDirection/v4IsUpvote``. Both extract the returned
    /// `post_view` and map it via `neutralPostView(fromV3:)`/`neutralPostView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the post to vote on.
    ///   - direction: the vote to cast: `.up`, `.down`, or `.none` to retract an existing vote.
    /// - Returns: the neutral `PostView` reflecting the new vote state.
    /// - Note: requires authentication.
    func votePostNeutral(id: Int64, direction: VoteDirection) async throws -> PostView {
        switch apiVersion {
        case .v3:
            try await votePostNeutralV3(id: id, direction: direction)
        case .v4:
            try await votePostNeutralV4(id: id, direction: direction)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``likePost(postID:status:)``, writing `direction.v3Score` directly instead of routing
    /// through `LikeStatus`, then maps the extracted v3 `post_view` up to the neutral shape.
    func votePostNeutralV3(id: Int64, direction: VoteDirection) async throws -> PostView {
        let postID = try v3PostID(id)

        let response: Operations.likePost.Output
        do {
            response = try await client.likePost(body: .json(.init(
                post_id: postID,
                score: Components.Schemas.MyVote(direction.v3Score)
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPostView(fromV3: json.post_view)
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

    /// v4 path: calls the v4 generated client's `LikePost` operation writing
    /// `direction.v4IsUpvote`, then maps the extracted v4 `post_view` near-directly to the
    /// neutral shape. v4's `LikePost` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func votePostNeutralV4(id: Int64, direction: VoteDirection) async throws -> PostView {
        let response: LemmyKitV4Generated.Operations.LikePost.Output
        do {
            response = try await v4Client.LikePost(body: .json(.init(
                is_upvote: direction.v4IsUpvote,
                post_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPostView(fromV4: json.post_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
