//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The instance's site info and the signed-in account's own info, fetched together via
/// ``LemmyApi/getSiteAndMyUserNeutral()``.
///
/// This exists to collapse a signed-in site refresh into the fewest round-trips each backend
/// allows. On a v3 backend the account's `my_user` is embedded in the single `GetSiteResponse`, so
/// both halves come from ONE `getSite()` call -- fetching them separately
/// (``LemmyApi/getSiteNeutral()`` then ``LemmyApi/getMyUserNeutral()``) would make v3 issue TWO
/// full `getSite` round-trips, since v3 has no standalone "get my account" endpoint. On a v4
/// backend the two are genuinely distinct endpoints
/// (`GetSite` and `GetMyUser`), so this makes both native calls; there is no redundancy to remove
/// there.
///
/// `myUser` is `nil` when the site loaded but no account info was returned -- on v3, a signed-out
/// viewer's `GetSiteResponse` carries no `my_user`. (On v4 a signed-out viewer instead surfaces as
/// a thrown error from the separate `GetMyUser` call, so a v4 result's `myUser` is non-nil whenever
/// the combined call returns.)
public struct SiteWithMyUser: Sendable, Equatable {
    /// The instance's site info -- the same value ``LemmyApi/getSiteNeutral()`` returns.
    public let site: SiteInfo

    /// The signed-in account's own info -- the same value ``LemmyApi/getMyUserNeutral()`` returns
    /// -- or `nil` when no account info accompanied the site (a signed-out viewer on v3).
    public let myUser: MyUser?

    public init(site: SiteInfo, myUser: MyUser?) {
        self.site = site
        self.myUser = myUser
    }
}
