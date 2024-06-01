//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public extension LemmyApi {
    func login(
        username: String,
        password: String
    ) async throws -> Components.Schemas.LoginResponse {
        let response = try await client.login(body: .json(.init(
            username_or_email: username,
            password: password
        )))
        return try response.ok.body.json
    }

    func login(
        username: String,
        password: String
    ) -> AnyPublisher<Components.Schemas.LoginResponse, LemmyApiError> {
        Future {
            try await self.login(
                username: username,
                password: password
            )
        }.eraseToAnyPublisher()
    }
}
