//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Resolve or reopen a private message report.
    ///
    /// - Parameters:
    ///   - reportID: the private message report to update.
    ///   - resolved: true to mark the report resolved, false to reopen it.
    /// - Note: requires authentication.
    func resolvePrivateMessageReport(
        reportID: Components.Schemas.PrivateMessageReportID,
        resolved: Bool
    ) async throws -> Components.Schemas.PrivateMessageReportResponse {
        let response: Operations.resolvePrivateMessageReport.Output
        do {
            response = try await client.resolvePrivateMessageReport(body: .json(.init(
                report_id: reportID,
                resolved: resolved
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
