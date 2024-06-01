//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func markPostAsRead(
        postIds: [Components.Schemas.PostID],
        read: Bool
    ) async throws -> Components.Schemas.SuccessResponse {
        let response = try await client.markPostAsRead(body: .json(.init(
            post_ids: postIds,
            read: read
        )))
        return try response.ok.body.json
    }

    func markPostAsRead(
        postIds: [Components.Schemas.PostID],
        read: Bool
    ) -> AnyPublisher<Components.Schemas.SuccessResponse, LemmyApiError> {
        Future {
            try await self.markPostAsRead(
                postIds: postIds,
                read: read
            )
        }.eraseToAnyPublisher()
    }
}
