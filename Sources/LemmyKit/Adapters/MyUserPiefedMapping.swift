//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `MyUser` for a PieFed `PiefedUserMeResponse` -- the "emulate upward" adapter
/// direction, the same pattern as `MyUserV3Mapping.swift`.
///
/// `localUserId` reads `local_user_view.person.id`, **not** `local_user.id` -- PieFed's
/// `local_user` carries no `id` field at all (see `PiefedLocalUser`'s doc); the account's identity
/// is the enclosing person's id.
///
/// PieFed's `local_user` is a large, alpha-stage settings bag (see `PiefedLocalUser`'s doc) that
/// carries only a handful of the settings this neutral type needs, under matching (if
/// differently-cased) names: `show_nsfw` -> `showNsfw`, `show_bot_accounts` -> `showBotAccounts`,
/// `show_read_posts` -> `showReadPosts`, `show_scores` -> `showScores` (each coalesced to `false`
/// if PieFed ever drops the key, since every field is `Optional` purely for decode-safety).
/// `default_listing_type`/`default_sort_type` are un-fused by the private helpers below, since
/// PieFed shares Lemmy v3's exact wire vocabulary for both (see `SortPiefedMapping.swift`'s doc).
///
/// Every other neutral setting has **no PieFed counterpart at all** and falls back to a default,
/// per `PiefedLocalUser`'s own doc ("the my-user adapter maps only the handful of preferences that
/// exist and falls back to the v3 mapping's defaults for the rest") and the Phase-1 PieFed
/// adapters' established "no signal -> false/nil" convention (see e.g.
/// `PersonPiefedMapping.swift`'s `matrixUserId: nil`, `CommunityViewPiefedMapping.swift`'s
/// `canMod: false`):
/// - `email`: no PieFed source (`PiefedLocalUser` has no `email` field) -- `nil`, matching
///   `MyUser.init`'s own default.
/// - `emailVerified`/`acceptedApplication`: no PieFed source -- `false`, the conservative
///   "not verified"/"not accepted" default.
/// - `isAdmin`: no PieFed source on this response's shape at all -- PieFed's admin flag rides
///   `PiefedPersonView.is_admin` on the authed `/site`'s `admins` list, which this function (fed
///   only a `PiefedUserMeResponse`) never sees -- `false`, same "no signal" default.
/// - `blurNsfw`/`showAvatars`: `PiefedLocalUser` has neither a `blur_nsfw` nor a `show_avatars`
///   field (its `nsfw_visibility` is a differently-shaped 4-state enum, not a drop-in replacement,
///   so this deliberately does not attempt to reinterpret it) -- `false`.
///
/// - Note: PieFed's `GET user/me` returns an EMPTY `follows` array while the authed `GET /site`'s
///   `my_user.follows` is populated (see `PiefedUserMeResponse`'s doc). This function maps
///   whatever `follows` the passed-in response carries -- the caller (the `getMyUserNeutral`
///   endpoint) is responsible for preferring the `/site` embed's response when the populated list
///   is needed.
package func neutralMyUser(fromPiefed response: PiefedUserMeResponse) -> MyUser {
    let local = response.local_user_view.local_user
    let (defaultSort, defaultTimeRange) = neutralPostSort(fromPiefedDefaultSortType: local.default_sort_type)

    return MyUser(
        person: neutralPerson(fromPiefed: response.local_user_view.person),
        localUserId: response.local_user_view.person.id,
        email: nil,
        emailVerified: false,
        acceptedApplication: false,
        isAdmin: false,
        showNsfw: local.show_nsfw ?? false,
        blurNsfw: false,
        showScores: local.show_scores ?? false,
        showBotAccounts: local.show_bot_accounts ?? false,
        showReadPosts: local.show_read_posts ?? false,
        showAvatars: false,
        defaultListingType: neutralListingType(fromPiefed: local.default_listing_type),
        defaultSort: defaultSort,
        defaultTimeRange: defaultTimeRange,
        follows: response.follows.map { neutralCommunity(fromPiefed: $0.community) },
        moderates: response.moderates.map(\.community.id)
    )
}

/// Builds the neutral `MyUser` for a PieFed authed-site response's `my_user` embed, additionally
/// deriving `isAdmin` from the enclosing site response's own `admins` list.
///
/// `neutralMyUser(fromPiefed:)` above always defaults `isAdmin` to `false` because a bare
/// `PiefedUserMeResponse` carries no admin flag of its own -- PieFed's admin standing instead
/// rides `PiefedPersonView.is_admin` on `PiefedGetSiteResponse.admins`, keyed by matching person
/// id. This overload is for callers that have that enclosing site response in hand (the
/// `getMyUserNeutral`/`getSiteAndMyUserNeutral` PieFed endpoints, which both source `MyUser` from
/// the authed `/site` embed per its doc) -- it builds the base mapping then overrides `isAdmin`
/// with the derived value.
///
/// - Parameters:
///   - response: the authed site response's `my_user` embed (`PiefedGetSiteResponse.my_user`,
///     already unwrapped by the caller).
///   - admins: the enclosing site response's `admins` list, searched for the signed-in account's
///     person id.
package func neutralMyUser(fromPiefed response: PiefedUserMeResponse, admins: [PiefedPersonView]) -> MyUser {
    let myUser = neutralMyUser(fromPiefed: response)
    let isAdmin = admins.contains { $0.person.id == response.local_user_view.person.id }

    return MyUser(
        person: myUser.person,
        localUserId: myUser.localUserId,
        email: myUser.email,
        emailVerified: myUser.emailVerified,
        acceptedApplication: myUser.acceptedApplication,
        isAdmin: isAdmin,
        showNsfw: myUser.showNsfw,
        blurNsfw: myUser.blurNsfw,
        showScores: myUser.showScores,
        showBotAccounts: myUser.showBotAccounts,
        showReadPosts: myUser.showReadPosts,
        showAvatars: myUser.showAvatars,
        defaultListingType: myUser.defaultListingType,
        defaultSort: myUser.defaultSort,
        defaultTimeRange: myUser.defaultTimeRange,
        follows: myUser.follows,
        moderates: myUser.moderates
    )
}

/// Folds PieFed's bare `default_listing_type` string onto `Lemmy.ListingType` (a v3-shaped alias --
/// see `NeutralVocabulary.swift`).
///
/// PieFed's vocabulary is Lemmy v3's four cases (`All`/`Local`/`Subscribed`/`ModeratorView`) plus
/// two PieFed-only extras with no v3/neutral equivalent (`Popular`, `Moderating`, per
/// `PiefedLocalUser.default_listing_type`'s doc) -- both those extras, an unrecognized string, and
/// `nil` (no PieFed source at all) fold to `.All`, the closest "everything" analogue: the same
/// fallback `MyUserV4Mapping.swift`'s `neutralListingType(fromV4:)` uses for v4's extra
/// `.suggested` case.
private func neutralListingType(fromPiefed type: String?) -> Lemmy.ListingType {
    switch type {
    case "All": .All
    case "Local": .Local
    case "Subscribed": .Subscribed
    case "ModeratorView": .ModeratorView
    default: .All
    }
}

/// Un-fuses PieFed's bare `default_sort_type` string into the neutral `PostSort` + `TimeRange`
/// pair, reusing `neutralPostSort(fromV3:)`'s un-fusing -- PieFed's `/api/alpha` accepts the
/// identical wire vocabulary as v3's `SortType` (see `SortPiefedMapping.swift`'s doc), so this
/// parses the string into `Components.Schemas.SortType` and hands it to the existing fold rather
/// than duplicating it.
///
/// Returns `(nil, nil)` when PieFed sends no default sort at all, or an unrecognized string --
/// matching `MyUser.defaultSort`/`defaultTimeRange`'s own nil defaults, since (unlike
/// `defaultListingType`) both are genuinely optional on the neutral type, so there is no need to
/// force a lossy fallback value the way `neutralListingType(fromPiefed:)` does.
private func neutralPostSort(fromPiefedDefaultSortType string: String?) -> (sort: PostSort?, timeRange: TimeRange?) {
    guard let string, let sortType = Components.Schemas.SortType(rawValue: string) else {
        return (nil, nil)
    }
    let (sort, timeRange) = neutralPostSort(fromV3: sortType)
    return (sort, timeRange)
}
