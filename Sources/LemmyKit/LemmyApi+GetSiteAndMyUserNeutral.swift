//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetches the instance's site info and the signed-in account's own info together, in the
    /// fewest round-trips each backend allows, returning the version-neutral ``SiteWithMyUser``.
    ///
    /// Prefer this over calling ``getSiteNeutral()`` and ``getMyUserNeutral()`` back to back for a
    /// signed-in site refresh: on a v3 backend those two would issue TWO full `getSite`
    /// round-trips, because v3 has no standalone "get my account" endpoint and ``getMyUserNeutral()``
    /// re-fetches `getSite()` to reach the embedded `my_user`. This method makes ONE `getSite()`
    /// call on v3 and decodes BOTH halves from that single `GetSiteResponse`.
    ///
    /// On a v4 backend the site and the account are genuinely distinct endpoints (`GetSite` and
    /// `GetMyUser`), with no `my_user` embedded in the site response, so this makes both native
    /// calls -- there is no redundant round-trip to remove there.
    ///
    /// - Returns: the neutral ``SiteWithMyUser``. Its `myUser` is `nil` when the site loaded but no
    ///   account info accompanied it -- on v3, a signed-out viewer's `GetSiteResponse` carries no
    ///   `my_user`. On v4 a signed-out viewer instead surfaces as a thrown error from the separate
    ///   `GetMyUser` call (see ``getMyUserNeutral()``), so a v4 result's `myUser` is non-nil.
    func getSiteAndMyUserNeutral() async throws -> SiteWithMyUser {
        switch apiVersion {
        case .v3:
            try await getSiteAndMyUserNeutralV3()
        case .v4:
            try await getSiteAndMyUserNeutralV4()
        case .piefed:
            try await getSiteAndMyUserNeutralPiefed()
        }
    }
}

private extension LemmyApi {
    /// v3 path: a SINGLE `getSite()` round-trip, decoding both the neutral ``SiteInfo`` and the
    /// neutral ``MyUser`` from that one `GetSiteResponse` via the same `neutralSiteInfo(fromV3:)`/
    /// `neutralMyUser(fromV3:)` adapters the standalone neutral calls use. Unlike
    /// ``getMyUserNeutral()``'s v3 path, a missing `my_user` (signed-out viewer) yields `nil`
    /// rather than throwing -- the site half is still valid, so the combined call succeeds with
    /// `myUser == nil`.
    func getSiteAndMyUserNeutralV3() async throws -> SiteWithMyUser {
        let response = try await getSite()
        return SiteWithMyUser(
            site: neutralSiteInfo(fromV3: response),
            myUser: response.my_user.map { neutralMyUser(fromV3: $0) }
        )
    }

    /// v4 path: the two native endpoints -- `GetSite` for the site and `GetMyUser` for the account
    /// -- since v4 removed `my_user` from `GetSiteResponse`. Dispatches through the standalone
    /// neutral calls (already on the v4 branch, so each resolves to its v4 backend path), so any
    /// error from `GetMyUser` (e.g. a signed-out viewer) propagates out of the combined call.
    func getSiteAndMyUserNeutralV4() async throws -> SiteWithMyUser {
        // The two v4 endpoints are independent, so issue them concurrently -- their
        // network round-trips overlap (each suspends the actor while awaiting I/O),
        // which is the whole point of a combined call on v4.
        async let site = getSiteNeutral()
        async let myUser = getMyUserNeutral()
        return try await SiteWithMyUser(site: site, myUser: myUser)
    }

    /// PieFed path: a SINGLE authed `getSite()` round-trip (via `PiefedClient.getSiteAuthed()`),
    /// decoding both the neutral `SiteInfo` and the neutral `MyUser` from that one
    /// `PiefedGetSiteResponse` -- mirrors the v3 path's one-round-trip shape, and for the same
    /// reason ``getMyUserNeutral()``'s PieFed path prefers this embed over `userMe()`: the
    /// dedicated `user/me` route's `follows` is observed empty. `myUser` is `nil` when the
    /// response carries no `my_user` embed (a signed-out viewer) rather than throwing -- the site
    /// half is still valid, so the combined call succeeds with `myUser == nil`, same as the v3
    /// path. `isAdmin` is derived from the response's own `admins` list via
    /// `neutralMyUser(fromPiefed:admins:)`, same as ``getMyUserNeutral()``'s PieFed path.
    func getSiteAndMyUserNeutralPiefed() async throws -> SiteWithMyUser {
        guard let piefedClient else {
            throw LemmyApiError.unsupportedByDialect(operation: "getSiteAndMyUser")
        }
        let response = try await piefedClient.getSiteAuthed()
        return SiteWithMyUser(
            site: neutralSiteInfo(fromPiefed: response),
            myUser: response.my_user.map { neutralMyUser(fromPiefed: $0, admins: response.admins) }
        )
    }
}
