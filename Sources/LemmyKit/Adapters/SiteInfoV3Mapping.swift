//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Site` for a v3 `Components.Schemas.SiteView`.
///
/// v3 spreads a site's identity/branding (`site`), creation timestamp + aggregate config
/// (`local_site`), and aggregate counts (`counts`) across three separate objects joined only by
/// `SiteView`; the neutral `Site` flattens all three, matching v4's shape (see `Site.swift`).
/// `publishedAt`/`updatedAt` are sourced from `local_site`, not the bare `site` object -- Spud has
/// never read the latter's own `published`/`updated`.
func neutralSite(fromV3 view: Components.Schemas.SiteView) -> Site {
    Site(
        id: Int64(view.site.id),
        name: view.site.name,
        summary: view.site.description,
        sidebar: view.site.sidebar,
        iconUrl: view.site.icon,
        bannerUrl: view.site.banner,
        apId: view.site.actor_id,
        publishedAt: view.local_site.published,
        updatedAt: view.local_site.updated,
        posts: view.counts.posts,
        comments: view.counts.comments,
        communities: view.counts.communities,
        users: view.counts.users,
        usersActiveDay: view.counts.users_active_day,
        usersActiveWeek: view.counts.users_active_week,
        usersActiveMonth: view.counts.users_active_month,
        usersActiveHalfYear: view.counts.users_active_half_year
    )
}

/// Builds the neutral `SiteInfo` for a v3 `Components.Schemas.GetSiteResponse`.
///
/// `taglines` is v3's rotating list of taglines a frontend picks one from at random; there is no
/// neutral notion of "pick one" at the LemmyKit layer, so this takes the first entry
/// (`taglines.first?.content`) -- v4 collapses this to a single server-chosen `tagline` outright
/// (see `SiteInfoV4Mapping.swift`). `my_user` is deliberately NOT read here: it is exposed via
/// ``LemmyApi/getMyUserNeutral()`` instead (see `MyUserV3Mapping.swift`).
func neutralSiteInfo(fromV3 response: Components.Schemas.GetSiteResponse) -> SiteInfo {
    SiteInfo(
        site: neutralSite(fromV3: response.site_view),
        version: response.version,
        tagline: response.taglines.first?.content,
        admins: response.admins.map { neutralPerson(fromV3: $0.person) }
    )
}
