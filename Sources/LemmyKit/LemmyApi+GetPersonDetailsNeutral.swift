//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a person's profile and moderation standing, and returns the version-neutral
    /// ``PersonDetails``.
    ///
    /// v4 splits person details in two: this method's v4 path calls `GetPersonDetails`, which
    /// returns only `person_view` + `moderates` (+ `multi_communities_created`, not carried
    /// across yet). The person's post/comment feed is a *separate*, paginated call on v4 -- see
    /// ``personContentNeutral(personId:pageCursor:)``. v3's single `getPersonDetails` call
    /// returns everything inline instead (`person_view` + `comments[]` + `posts[]` +
    /// `moderates`); this method's v3 path deliberately discards the inline `comments`/`posts` --
    /// they're served by `personContentNeutral` instead, whose v3 path re-fetches this same
    /// endpoint and interleaves them (see that method's doc for why the split is emulated that
    /// way rather than reusing the arrays already fetched here).
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's
    /// `getPersonDetails` mapped "up" via `neutralPersonView(fromV3:)`, or the v4 client's
    /// `GetPersonDetails` mapped near-directly via `neutralPersonView(fromV4:)`.
    ///
    /// - Parameter personId: the person whose details to fetch.
    /// - Returns: the neutral `PersonDetails` for the requested person.
    func personDetailsNeutral(personId: Int64) async throws -> PersonDetails {
        switch apiVersion {
        case .v3:
            try await personDetailsNeutralV3(personId: personId)
        case .v4:
            try await personDetailsNeutralV4(personId: personId)
        case .piefed:
            try await personDetailsNeutralPiefed(personId: personId)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``getPersonDetails(personID:sort:page:limit:)``, then maps the extracted `person_view` up
    /// to the neutral shape and the `moderates` community-moderator views down to bare community
    /// ids. The response's inline `comments`/`posts` are intentionally ignored here -- see this
    /// method's doc.
    func personDetailsNeutralV3(personId: Int64) async throws -> PersonDetails {
        let personID = try v3PersonID(personId)

        let response: Operations.getPersonDetails.Output
        do {
            response = try await client.getPersonDetails(query: .init(person_id: personID))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return PersonDetails(
                    personView: neutralPersonView(fromV3: json.person_view),
                    moderates: json.moderates.map { Int64($0.community.id) }
                )
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

    /// v4 path: calls the v4 generated client's `GetPersonDetails` operation, then maps the
    /// extracted `person_view` near-directly to the neutral shape and the `moderates`
    /// community-moderator views down to bare community ids. v4's `GetPersonDetails` only
    /// documents the `ok` response (no `unauthorized`/`badRequest` cases like v3), so anything
    /// else falls through to `.undocumented`.
    func personDetailsNeutralV4(personId: Int64) async throws -> PersonDetails {
        let response: LemmyKitV4Generated.Operations.GetPersonDetails.Output
        do {
            response = try await v4Client.GetPersonDetails(query: .init(person_id: personId))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return PersonDetails(
                    personView: neutralPersonView(fromV4: json.person_view),
                    moderates: json.moderates.map(\.community.id)
                )
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.getPersonDetails(personId:includeContent:)` with
    /// `includeContent: false` -- unlike v3/v4, PieFed's route genuinely supports omitting the
    /// posts/comments payload, so this skips fetching content this method doesn't return anyway
    /// (`personContentNeutral(personId:pageCursor:)` fetches it separately, with
    /// `includeContent: true`) -- then maps the extracted `person_view` + `moderates` to the
    /// neutral shape via `neutralPersonDetails(fromPiefed:)`.
    func personDetailsNeutralPiefed(personId: Int64) async throws -> PersonDetails {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "personDetails") }
        let response = try await piefedClient.getPersonDetails(personId: personId, includeContent: false)
        return neutralPersonDetails(fromPiefed: response)
    }
}
