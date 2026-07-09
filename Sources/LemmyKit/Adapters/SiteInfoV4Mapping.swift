//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `Site` for a v4 `Components.Schemas.SiteView`.
///
/// v4 moved the aggregate counts (`users`/`posts`/`comments`/`users_active_*`) that v3 keeps on a
/// separate `SiteAggregates` (`SiteView.counts`) directly onto `LocalSite` -- there is no v4
/// `counts` field on `SiteView` at all. `publishedAt`/`updatedAt` are likewise sourced from
/// `local_site`, not the bare `site` object, matching the v3 adapter (see `SiteInfoV3Mapping.swift`).
func neutralSite(fromV4 view: LemmyKitV4Generated.Components.Schemas.SiteView) -> Site {
    Site(
        id: view.site.id,
        name: view.site.name,
        summary: view.site.summary,
        sidebar: view.site.sidebar,
        iconUrl: view.site.icon,
        bannerUrl: view.site.banner,
        apId: view.site.ap_id,
        publishedAt: v4Date(required: view.local_site.published_at),
        updatedAt: v4Date(view.local_site.updated_at),
        posts: view.local_site.posts,
        comments: view.local_site.comments,
        communities: view.local_site.communities,
        users: view.local_site.users,
        usersActiveDay: view.local_site.users_active_day,
        usersActiveWeek: view.local_site.users_active_week,
        usersActiveMonth: view.local_site.users_active_month,
        usersActiveHalfYear: view.local_site.users_active_half_year
    )
}

/// Builds the neutral `SiteInfo` for a v4 `Components.Schemas.GetSiteResponse`.
///
/// v4's `GetSiteResponse` has no `my_user` field at all (see `MyUserV4Mapping.swift`'s
/// `GetMyUser` path instead) -- unlike the v3 adapter, there is nothing to deliberately skip here.
func neutralSiteInfo(fromV4 response: LemmyKitV4Generated.Components.Schemas.GetSiteResponse) -> SiteInfo {
    SiteInfo(
        site: neutralSite(fromV4: response.site_view),
        version: response.version,
        tagline: response.tagline?.content,
        admins: response.admins.map { neutralPerson(fromV4: $0.person) }
    )
}
