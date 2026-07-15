//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Resolves a federated ActivityPub object -- a post, comment, community, or person -- by its
    /// url or fully-qualified name (e.g. `!fediverse@lemmy.ml`), returning the version-neutral
    /// discriminated ``ResolvedObject``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``): the v3 client's `resolveObject` maps its four-optionals response "up" via
    /// `neutralResolvedObject(fromV3:)`, while the v4 client's `ResolveObject` maps its
    /// discriminated-union response near-directly via `neutralResolvedObject(fromV4:)`.
    ///
    /// - Parameter query: the federated object url or handle to resolve.
    /// - Returns: the resolved object, or nil if `query` couldn't be resolved to a post, comment,
    ///   community, or person. This includes a v4 backend resolving to a `MultiCommunity`, which
    ///   has no neutral counterpart -- see ``ResolvedObject``.
    func resolveObjectNeutral(query: String) async throws -> ResolvedObject? {
        switch apiVersion {
        case .v3:
            try await resolveObjectNeutralV3(query: query)
        case .v4:
            try await resolveObjectNeutralV4(query: query)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "resolveObject")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``resolveObject(query:)``, then maps the extracted v3 response up to the neutral shape.
    func resolveObjectNeutralV3(query: String) async throws -> ResolvedObject? {
        let response: Operations.resolveObject.Output
        do {
            response = try await client.resolveObject(query: .init(
                q: query
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralResolvedObject(fromV3: json)
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

    /// v4 path: calls the v4 generated client's `ResolveObject` operation, then maps the
    /// extracted v4 discriminated-union response near-directly to the neutral shape. v4's
    /// `ResolveObject` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func resolveObjectNeutralV4(query: String) async throws -> ResolvedObject? {
        let response: LemmyKitV4Generated.Operations.ResolveObject.Output
        do {
            response = try await v4Client.ResolveObject(query: .init(
                q: query
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralResolvedObject(fromV4: json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
