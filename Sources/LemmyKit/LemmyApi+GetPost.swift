//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    /// Fetch a post by its id.
    func getPost(
        id: Components.Schemas.PostID
    ) async throws -> Components.Schemas.GetPostResponse {
        let response = try await client.getPost(.init(query: .init(
            id: id
        )))
        return try response.ok.body.json
    }

    /// Fetch a post by its id.
    func getPost(
        id: Components.Schemas.PostID
    ) -> AnyPublisher<Components.Schemas.GetPostResponse, LemmyApiError> {
        Future {
            try await self.getPost(id: id)
        }.eraseToAnyPublisher()
    }
}
