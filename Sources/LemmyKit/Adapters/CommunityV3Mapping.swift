//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Community` for a v3 `Components.Schemas.Community`.
///
/// v3's bare `Community` (the shape embedded in `PostView.community`) carries no
/// subscriber/post/comment tallies -- those live on `CommunityAggregates`, reachable only
/// through a separate `CommunityView`. There is no v3 source for `subscribers`/`posts`/
/// `comments` in this context, so all three default to `0`.
func neutralCommunity(fromV3 community: Components.Schemas.Community) -> Community {
    Community(
        id: Int64(community.id),
        name: community.name,
        title: community.title,
        sidebar: community.description,
        apId: community.actor_id,
        iconUrl: community.icon,
        bannerUrl: community.banner,
        visibility: neutralCommunityVisibility(fromV3Hidden: community.hidden, visibility: community.visibility),
        local: community.local,
        nsfw: community.nsfw,
        postingRestrictedToMods: community.posting_restricted_to_mods,
        removed: community.removed,
        deleted: community.deleted,
        publishedAt: community.published,
        updatedAt: community.updated,
        subscribers: 0,
        posts: 0,
        comments: 0
    )
}

/// Builds the neutral `Community` for a v3 `Components.Schemas.Community` plus its
/// `CommunityAggregates` ("counts") -- the shape of a v3 `CommunityView`, which (unlike the bare
/// `Community` embedded in `PostView`/`CommentView`) carries a sibling `counts` field. Mirrors
/// `neutralPost(fromV3:counts:)`: every field but `subscribers`/`posts`/`comments` comes from
/// `community` itself, and those three come from `counts`, flattening onto the neutral shape to
/// match v4's `Community`.
func neutralCommunity(
    fromV3 community: Components.Schemas.Community,
    counts: Components.Schemas.CommunityAggregates
) -> Community {
    Community(
        id: Int64(community.id),
        name: community.name,
        title: community.title,
        sidebar: community.description,
        apId: community.actor_id,
        iconUrl: community.icon,
        bannerUrl: community.banner,
        visibility: neutralCommunityVisibility(fromV3Hidden: community.hidden, visibility: community.visibility),
        local: community.local,
        nsfw: community.nsfw,
        postingRestrictedToMods: community.posting_restricted_to_mods,
        removed: community.removed,
        deleted: community.deleted,
        publishedAt: community.published,
        updatedAt: community.updated,
        subscribers: counts.subscribers,
        posts: counts.posts,
        comments: counts.comments
    )
}

/// Maps v3's community visibility signal to the neutral `CommunityVisibility`.
///
/// v3 actually carries *two* overlapping signals, both still present in the current spec:
/// a plain `hidden: Bool` (`"Whether the community is hidden"`) and its own `visibility:
/// CommunityVisibility` enum, which only has `Public`/`LocalOnly` cases (a strict subset of the
/// neutral/v4 enum -- no `Private` case). `hidden` takes priority when set, since "not shown in
/// public directories" (the neutral `.unlisted`) is the one v3 state that isn't otherwise
/// representable via `visibility` alone. `.localOnlyPrivate`/`._private` are v4-only; v3 never
/// produces them.
private func neutralCommunityVisibility(
    fromV3Hidden hidden: Bool,
    visibility: Components.Schemas.CommunityVisibility
) -> CommunityVisibility {
    if hidden {
        return .unlisted
    }
    switch visibility {
    case .Public:
        return ._public
    case .LocalOnly:
        return .localOnlyPublic
    }
}
