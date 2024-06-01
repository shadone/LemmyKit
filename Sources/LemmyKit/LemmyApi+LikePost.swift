//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Update the post like status to be as specified by `status`.
    func likePost(
        _ postID: Components.Schemas.PostID,
        status: LikeStatus
    ) async throws -> Components.Schemas.PostResponse {
        let response = try await client.likePost(body: .json(.init(
            post_id: postID,
            score: status.rawValue
        )))
        return try response.ok.body.json
    }

    /// Update the post like status to be as specified by `status`.
    func likePost(
        _ postID: Components.Schemas.PostID,
        status: LikeStatus
    ) -> AnyPublisher<Components.Schemas.PostResponse, LemmyApiError> {
        Future {
            try await self.likePost(postID, status: status)
        }.eraseToAnyPublisher()
    }
}
