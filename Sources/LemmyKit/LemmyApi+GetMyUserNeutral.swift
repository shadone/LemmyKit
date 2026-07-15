//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches the signed-in account's own settings and standing, returning the version-neutral
    /// ``MyUser``.
    ///
    /// v4 REMOVED `my_user` from `GetSiteResponse` and moved it to its own `GET /api/v4/account`
    /// operation (`GetMyUser`) -- the v4 path below calls that directly. v3 has no equivalent
    /// standalone endpoint, so the v3 path re-fetches ``getSite()`` and extracts `my_user` from
    /// the response.
    ///
    /// This re-fetch is a known inefficiency: a caller that already holds a fresh
    /// `GetSiteResponse` (e.g. from a just-completed ``getSiteNeutral()`` call) duplicates a
    /// network round-trip by also calling this method on a v3 backend. Sharing/caching that one
    /// response across both neutral calls is a noted follow-up, out of scope here -- the my_user
    /// split only requires the two calls to be independently correct.
    ///
    /// - Returns: the neutral `MyUser` for the signed-in account.
    /// - Throws: ``LemmyApiError/unauthorized(message:)`` on a v3 backend if the re-fetched
    ///   response carries no `my_user` (the account is signed out).
    func getMyUserNeutral() async throws -> MyUser {
        switch apiVersion {
        case .v3:
            try await getMyUserNeutralV3()
        case .v4:
            try await getMyUserNeutralV4()
        case .piefed:
            try await getMyUserNeutralPiefed()
        }
    }
}

private extension LemmyApi {
    /// v3 path: re-fetches ``getSite()`` and extracts `my_user`, since v3 has no standalone
    /// "get my account" endpoint. Throws `.unauthorized` if `my_user` is nil -- the response is
    /// for a signed-out viewer, who has no account settings to return.
    func getMyUserNeutralV3() async throws -> MyUser {
        let response = try await getSite()
        guard let myUser = response.my_user else {
            throw LemmyApiError.unauthorized(message: nil)
        }
        return neutralMyUser(fromV3: myUser)
    }

    /// v4 path: calls the v4 generated client's `GetMyUser` operation (`GET /account`), then maps
    /// the extracted `MyUserInfo` near-directly to the neutral shape. Like ``getPostNeutral(id:)``'s
    /// v4 path, v4's `GetMyUser` only documents the `ok` response, so anything else falls through
    /// to `.undocumented`.
    func getMyUserNeutralV4() async throws -> MyUser {
        let response: LemmyKitV4Generated.Operations.GetMyUser.Output
        do {
            response = try await v4Client.GetMyUser()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralMyUser(fromV4: json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.getSiteAuthed()` -- **not** `userMe()` -- since PieFed's
    /// dedicated `user/me` route is observed to return an EMPTY `follows` array while the authed
    /// `/site`'s `my_user` embed carries the account's live subscriptions (see
    /// `PiefedClient.userMe()`'s doc). Throws `.unauthorized` if the response carries no `my_user`
    /// at all -- a signed-out viewer has no account settings to return, matching the v3 path's
    /// same-shaped throw. `isAdmin` is derived from the response's own `admins` list via
    /// `neutralMyUser(fromPiefed:admins:)`, since PieFed's `my_user` embed carries no admin flag
    /// of its own.
    func getMyUserNeutralPiefed() async throws -> MyUser {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getMyUser") }
        let response = try await piefedClient.getSiteAuthed()
        guard let myUser = response.my_user else {
            throw LemmyApiError.unauthorized(message: nil)
        }
        return neutralMyUser(fromPiefed: myUser, admins: response.admins)
    }
}
