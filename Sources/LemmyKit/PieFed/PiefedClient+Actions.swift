//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension PiefedClient {
    // MARK: - Vote / save / follow

    /// `POST /api/alpha/post/like` -- vote on a post.
    ///
    /// - Parameters:
    ///   - postId: the post id.
    ///   - score: `-1` (downvote), `0` (revert previous vote), or `1` (upvote).
    func likePost(postId: Int64, score: Int) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/like",
            body: PiefedLikePostRequestBody(post_id: postId, score: score),
            operationID: "likePost"
        )
    }

    /// `POST /api/alpha/comment/like` -- vote on a comment. See ``likePost(postId:score:)`` for
    /// `score` semantics.
    func likeComment(commentId: Int64, score: Int) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment/like",
            body: PiefedLikeCommentRequestBody(comment_id: commentId, score: score),
            operationID: "likeComment"
        )
    }

    /// `PUT /api/alpha/post/save` -- bookmark/unbookmark a post. **PUT**, not POST (unlike vote).
    func savePost(postId: Int64, save: Bool) async throws -> PiefedPostResponse {
        try await send(
            .put, "/api/alpha/post/save",
            body: PiefedSavePostRequestBody(post_id: postId, save: save),
            operationID: "savePost"
        )
    }

    /// `PUT /api/alpha/comment/save` -- bookmark/unbookmark a comment. **PUT**, not POST.
    func saveComment(commentId: Int64, save: Bool) async throws -> PiefedCommentResponse {
        try await send(
            .put, "/api/alpha/comment/save",
            body: PiefedSaveCommentRequestBody(comment_id: commentId, save: save),
            operationID: "saveComment"
        )
    }

    /// `POST /api/alpha/community/follow` -- the membership follow/unfollow (Lemmy's
    /// `follow_community` equivalent). Not to be confused with PieFed's separate
    /// `PUT /community/subscribe` activity-alert toggle, which has no Lemmy v3 equivalent and
    /// isn't exposed here.
    ///
    /// - Returns: the updated ``PiefedCommunityView``, whose `subscribed` is the three-case string
    ///   enum `"NotSubscribed"`/`"Subscribed"`/`"Pending"`, not a bool.
    func followCommunity(communityId: Int64, follow: Bool) async throws -> PiefedCommunityFollowResponse {
        try await send(
            .post, "/api/alpha/community/follow",
            body: PiefedFollowCommunityRequestBody(community_id: communityId, follow: follow),
            operationID: "followCommunity"
        )
    }
}
