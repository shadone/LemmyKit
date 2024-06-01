//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func getSite() async throws -> Components.Schemas.GetSiteResponse {
        let response = try await client.getSite()
        return try response.ok.body.json
    }

    func getSite() -> AnyPublisher<Components.Schemas.GetSiteResponse, LemmyApiError> {
        Future {
            try await self.getSite()
        }.eraseToAnyPublisher()
    }
}
