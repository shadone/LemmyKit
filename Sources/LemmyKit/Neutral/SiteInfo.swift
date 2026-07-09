//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The result of fetching a Lemmy instance's site info via ``LemmyApi/getSiteNeutral()``,
/// decoupled from the generated OpenAPI schema.
///
/// This wraps the neutral ``Site`` (the site's own identity/branding and aggregate counts)
/// together with the fields that only exist on the `GetSiteResponse` *operation result*, not on
/// the site entity itself: the server `version` string, a single `tagline`, and the site's
/// `admins`. v4-shaped: v4 replaced v3's rotating `taglines: [Tagline]` array with a single
/// server-chosen `tagline`, so this carries one `tagline: String?` rather than a list -- a V3
/// backend adapter takes `taglines.first?.content`. The signed-in account's own `MyUser` is
/// deliberately NOT here: v4 REMOVED `my_user` from `GetSiteResponse` entirely (the current user
/// is now its own operation, `GET /api/v4/account`), so it is fetched separately via
/// ``LemmyApi/getMyUserNeutral()``. See the design doc's "Site / MyUser (my_user split)" section.
public struct SiteInfo: Sendable, Equatable {
    /// The site's identity, branding, and aggregate counts.
    public let site: Site

    /// The running Lemmy server version string, e.g. `"0.19.18"`.
    public let version: String

    /// The site's current tagline, or `nil` if none is configured.
    public let tagline: String?

    /// The site's administrators, in server-provided order.
    public let admins: [Person]

    public init(
        site: Site,
        version: String,
        tagline: String? = nil,
        admins: [Person] = []
    ) {
        self.site = site
        self.version = version
        self.tagline = tagline
        self.admins = admins
    }
}
