//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Site` for a PieFed `PiefedSiteView`.
///
/// PieFed's `/api/alpha/site` response is far leaner than v3's `SiteView`: it carries no `id`, no
/// creation/edit timestamps, no `banner`, and none of the aggregate counts (posts/comments/
/// communities/active-user tallies) v3 spreads across `site`/`local_site`/`counts`. Only `name`,
/// `description` (-> `summary`), an icon, and `user_count` (-> `users`) have a real PieFed source;
/// every other neutral field defaults as noted below -- see the task report for the full list.
///
/// `sidebar` reads `sidebar_md` (the markdown source) rather than `sidebar` (PieFed's
/// server-rendered HTML of the same content) -- matching the neutral field's documented "in
/// markdown" contract, the same reasoning as `neutralPerson(fromPiefed:)`'s `bio`.
func neutralSite(fromPiefed view: PiefedSiteView) -> Site {
    Site(
        // PieFed's site view carries no numeric id at all -- there is nothing to map, so this
        // defaults to `0` rather than a fabricated value; no current consumer keys off `Site.id`
        // for a PieFed-backed site.
        id: 0,
        name: view.name,
        summary: view.description,
        sidebar: view.sidebar_md ?? view.sidebar,
        iconUrl: view.icon,
        // PieFed's site view has no banner field.
        bannerUrl: nil,
        apId: view.actor_id,
        // PieFed's site view has no creation/edit timestamp of any kind.
        publishedAt: Date(timeIntervalSince1970: 0),
        updatedAt: nil,
        // PieFed's site view carries no post/comment/community/active-user aggregate counts.
        posts: 0,
        comments: 0,
        communities: 0,
        users: view.user_count,
        usersActiveDay: 0,
        usersActiveWeek: 0,
        usersActiveMonth: 0,
        usersActiveHalfYear: 0
    )
}

/// Builds the neutral `SiteInfo` for a PieFed `PiefedGetSiteResponse`.
///
/// PieFed has no tagline field of any kind (neither v3's rotating `taglines` list nor v4's single
/// `tagline`), so `tagline` is always `nil` here. `my_user` is deliberately NOT read here, same as
/// v3/v4: it is exposed via ``LemmyApi/getMyUserNeutral()`` instead once PieFed auth lands (Phase
/// 2) -- and is absent entirely from a signed-out PieFed response in any case.
func neutralSiteInfo(fromPiefed response: PiefedGetSiteResponse) -> SiteInfo {
    SiteInfo(
        site: neutralSite(fromPiefed: response.site),
        version: response.version,
        tagline: nil,
        admins: response.admins.map { neutralPerson(fromPiefed: $0.person) }
    )
}
