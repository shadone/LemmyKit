//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Update the comment like status to be as specified by `status`.
    func likeComment(
        _ commentID: Components.Schemas.CommentID,
        status: LikeStatus
    ) async throws -> Components.Schemas.CommentResponse {
        let response = try await client.likeComment(body: .json(.init(
            comment_id: commentID,
            score: status.rawValue
        )))
        return try response.ok.body.json
    }

    /// Update the comment like status to be as specified by `status`.
    func likeComment(
        _ commentID: Components.Schemas.CommentID,
        status: LikeStatus
    ) -> AnyPublisher<Components.Schemas.CommentResponse, LemmyApiError> {
        Future {
            try await self.likeComment(commentID, status: status)
        }.eraseToAnyPublisher()
    }
}
