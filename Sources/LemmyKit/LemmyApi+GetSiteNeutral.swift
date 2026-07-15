//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches the instance's site info and returns the version-neutral ``SiteInfo``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as ``getPostNeutral(id:)``: the v3 client's
    /// `getSite` mapped "up" via `neutralSiteInfo(fromV3:)`, or the v4 client's `GetSite` mapped
    /// near-directly via `neutralSiteInfo(fromV4:)`.
    ///
    /// v4 REMOVED `my_user` from `GetSiteResponse` -- the signed-in account's own info is now its
    /// own operation -- so neither backend path surfaces it here, even though v3's raw response
    /// still carries it alongside the site data. Fetch it separately via ``getMyUserNeutral()``.
    ///
    /// - Returns: the neutral `SiteInfo` for this instance.
    func getSiteNeutral() async throws -> SiteInfo {
        switch apiVersion {
        case .v3:
            try await getSiteNeutralV3()
        case .v4:
            try await getSiteNeutralV4()
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "getSite")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as ``getSite()``,
    /// then maps the extracted response up to the neutral shape -- DROPPING `my_user` here (see
    /// ``getMyUserNeutral()``, whose v3 path re-fetches this same response to extract it).
    func getSiteNeutralV3() async throws -> SiteInfo {
        let response: Operations.getSite.Output
        do {
            response = try await client.getSite()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralSiteInfo(fromV3: json)
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

    /// v4 path: calls the v4 generated client's `GetSite` operation, then maps the extracted
    /// response near-directly to the neutral shape. Like ``getPostNeutral(id:)``'s v4 path, v4's
    /// `GetSite` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func getSiteNeutralV4() async throws -> SiteInfo {
        let response: LemmyKitV4Generated.Operations.GetSite.Output
        do {
            response = try await v4Client.GetSite()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralSiteInfo(fromV4: json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
