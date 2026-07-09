//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Blocks or unblocks the person `id` for the signed-in account and returns the
    /// version-neutral ``PersonView`` for the (un)blocked person.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's
    /// `blockPerson` mapped "up" via `neutralPersonView(fromV3:)`, or the v4 client's
    /// `BlockPerson` mapped near-directly via `neutralPersonView(fromV4:)`. Both response bodies
    /// also carry a `blocked` flag confirming the request took effect, but since it always
    /// mirrors the `block` argument on success, this method doesn't surface it separately --
    /// only the resulting `PersonView` is returned.
    ///
    /// - Parameters:
    ///   - id: the person to block or unblock.
    ///   - block: true to block the person, false to unblock.
    /// - Returns: the neutral `PersonView` for the (un)blocked person.
    /// - Note: requires authentication.
    func blockPersonNeutral(id: Int64, block: Bool) async throws -> PersonView {
        switch apiVersion {
        case .v3:
            try await blockPersonNeutralV3(id: id, block: block)
        case .v4:
            try await blockPersonNeutralV4(id: id, block: block)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``blockPerson(personID:block:)``, then maps the extracted v3 `person_view` up to the
    /// neutral shape.
    func blockPersonNeutralV3(id: Int64, block: Bool) async throws -> PersonView {
        let personID = try v3PersonID(id)

        let response: Operations.blockPerson.Output
        do {
            response = try await client.blockPerson(body: .json(.init(
                person_id: personID,
                block: block
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPersonView(fromV3: json.person_view)
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

    /// v4 path: calls the v4 generated client's `BlockPerson` operation, then maps the extracted
    /// v4 `person_view` near-directly to the neutral shape. Unlike v3's `BlockPersonResponse`,
    /// v4's `BlockPerson` returns a bare `PersonResponse` (`{ person_view }`, no top-level
    /// `blocked` flag) -- not needed here regardless, since this method only returns the
    /// `PersonView`. v4's `BlockPerson` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func blockPersonNeutralV4(id: Int64, block: Bool) async throws -> PersonView {
        let response: LemmyKitV4Generated.Operations.BlockPerson.Output
        do {
            response = try await v4Client.BlockPerson(body: .json(.init(
                block: block,
                person_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPersonView(fromV4: json.person_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
