//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Approve or deny a registration application.
    ///
    /// - Parameters:
    ///   - id: the registration application to act on.
    ///   - approve: true to approve the application, false to deny it.
    ///   - denyReason: optional reason shown to the applicant when denied; omitted when not provided.
    /// - Note: admin only.
    func approveRegistrationApplication(
        id: Int32,
        approve: Bool,
        denyReason: String? = nil
    ) async throws -> Components.Schemas.RegistrationApplicationResponse {
        let response: Operations.approveRegistrationApplication.Output
        do {
            response = try await client.approveRegistrationApplication(body: .json(.init(
                id: id,
                approve: approve,
                deny_reason: denyReason
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
