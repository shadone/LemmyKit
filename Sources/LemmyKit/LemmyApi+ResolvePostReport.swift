//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Resolve or unresolve the post report `reportID`.
    /// - Parameters:
    ///   - resolved: Pass `true` to mark the report resolved, `false` to reopen it.
    func resolvePostReport(
        reportID: Components.Schemas.PostReportID,
        resolved: Swift.Bool
    ) async throws -> Components.Schemas.PostReportResponse {
        let response: Operations.resolvePostReport.Output
        do {
            response = try await client.resolvePostReport(body: .json(.init(
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
