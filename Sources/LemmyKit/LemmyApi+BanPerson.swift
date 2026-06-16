//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Ban the person `personID` from the instance.
    ///
    /// - Parameters:
    ///   - personID: the person to ban.
    ///   - removeData: true to also remove all of the person's posts and comments.
    ///   - reason: optional reason recorded in the mod log.
    ///   - expires: when the ban should lift; nil for a permanent ban.
    /// - Note: admin only.
    func banPerson(
        personID: Components.Schemas.PersonID,
        removeData: Bool? = nil,
        reason: String? = nil,
        expires: Date? = nil
    ) async throws -> Components.Schemas.BanPersonResponse {
        try await sendBanPerson(.init(
            person_id: personID,
            ban: true,
            remove_data: removeData,
            reason: reason,
            expires: expires.map { Int64($0.timeIntervalSince1970) }
        ))
    }

    /// Lift an existing instance ban on the person `personID`.
    ///
    /// - Parameters:
    ///   - personID: the person to unban.
    ///   - reason: optional reason recorded in the mod log.
    /// - Note: admin only.
    func unbanPerson(
        personID: Components.Schemas.PersonID,
        reason: String? = nil
    ) async throws -> Components.Schemas.BanPersonResponse {
        try await sendBanPerson(.init(
            person_id: personID,
            ban: false,
            remove_data: nil,
            reason: reason,
            expires: nil
        ))
    }

    private func sendBanPerson(
        _ body: Components.Schemas.BanPerson
    ) async throws -> Components.Schemas.BanPersonResponse {
        let response: Operations.banPerson.Output
        do {
            response = try await client.banPerson(body: .json(body))
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
