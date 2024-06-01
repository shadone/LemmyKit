//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func getPersonDetails(
        personId: Components.Schemas.PersonID
    ) async throws -> Components.Schemas.GetPersonDetailsResponse {
        let response = try await client.getPersonDetails(query: .init(
            person_id: personId
        ))
        return try response.ok.body.json
    }

    func getPersonDetails(
        personId: Components.Schemas.PersonID
    ) -> AnyPublisher<Components.Schemas.GetPersonDetailsResponse, LemmyApiError> {
        Future {
            try await self.getPersonDetails(personId: personId)
        }.eraseToAnyPublisher()
    }
}
