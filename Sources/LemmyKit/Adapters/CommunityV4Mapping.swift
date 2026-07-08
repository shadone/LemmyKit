//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `Community` for a v4 `Components.Schemas.Community`.
///
/// v4 already flattens `subscribers`/`posts`/`comments` directly onto `Community`, matching the
/// neutral shape 1:1 -- unlike v3, whose bare `Community` (embedded in `PostView.community`) has
/// no tallies at all (see `CommunityV3Mapping.swift`).
func neutralCommunity(fromV4 community: LemmyKitV4Generated.Components.Schemas.Community) -> Community {
    Community(
        id: community.id,
        name: community.name,
        title: community.title,
        sidebar: community.sidebar,
        apId: community.ap_id,
        iconUrl: community.icon,
        bannerUrl: community.banner,
        visibility: neutralCommunityVisibility(fromV4: community.visibility),
        local: community.local,
        nsfw: community.nsfw,
        postingRestrictedToMods: community.posting_restricted_to_mods,
        removed: community.removed,
        deleted: community.deleted,
        publishedAt: v4Date(required: community.published_at),
        updatedAt: v4Date(community.updated_at),
        subscribers: community.subscribers,
        posts: community.posts,
        comments: community.comments
    )
}

/// Maps v4's `CommunityVisibility` 1:1 onto the neutral enum -- the case sets match exactly.
private func neutralCommunityVisibility(
    fromV4 visibility: LemmyKitV4Generated.Components.Schemas.CommunityVisibility
) -> CommunityVisibility {
    switch visibility {
    case ._public:
        ._public
    case .unlisted:
        .unlisted
    case .local_only_public:
        .localOnlyPublic
    case .local_only_private:
        .localOnlyPrivate
    case ._private:
        ._private
    }
}
