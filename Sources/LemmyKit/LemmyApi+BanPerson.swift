//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Ban or unban a person from the instance.
    ///
    /// - Parameters:
    ///   - removeData: Optionally remove all their data. Useful for new troll accounts.
    ///   - expires: A time that the ban will expire, in unix epoch seconds.
    func banPerson(
        personID: Components.Schemas.PersonID,
        ban: Bool,
        removeData: Bool? = nil,
        reason: String? = nil,
        expires: Int64? = nil
    ) async throws -> Components.Schemas.BanPersonResponse {
        let response: Operations.banPerson.Output
        do {
            response = try await client.banPerson(body: .json(.init(
                person_id: personID,
                ban: ban,
                remove_data: removeData,
                reason: reason,
                expires: expires
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
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
}
