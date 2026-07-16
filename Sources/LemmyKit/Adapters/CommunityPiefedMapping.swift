//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `Community` for a bare PieFed `PiefedCommunity` -- the shape embedded in a
/// post/comment's `community` field, which carries no subscriber/post/comment tallies (those live
/// on `PiefedCommunityCounts`, reachable only through a `PiefedCommunityView`). There is no PieFed
/// source for `subscribers`/`posts`/`comments` in this context, so all three default to `0`,
/// matching the equivalent v3 overload.
func neutralCommunity(fromPiefed community: PiefedCommunity) -> Community {
    Community(
        id: community.id,
        name: community.name,
        title: community.title,
        sidebar: community.description,
        apId: community.actor_id,
        iconUrl: community.icon,
        bannerUrl: community.banner,
        visibility: neutralCommunityVisibility(fromPiefedHidden: community.hidden),
        local: community.local,
        nsfw: community.nsfw,
        postingRestrictedToMods: community.restricted_to_mods,
        removed: community.removed,
        deleted: community.deleted,
        publishedAt: piefedDate(community.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: piefedDate(community.updated),
        subscribers: 0,
        posts: 0,
        comments: 0
    )
}

/// Builds the neutral `Community` for a PieFed `PiefedCommunity` plus its `PiefedCommunityCounts`
/// -- the shape of a PieFed `PiefedCommunityView` (`community/list`, `community`, `search`), which
/// (unlike the bare `PiefedCommunity` embedded in a post/comment) carries a sibling `counts`
/// field. Mirrors the v3 counted overload: every field but `subscribers`/`posts`/`comments` comes
/// from `community` itself, and those three come from `counts`.
///
/// `subscribers` reads `total_subscriptions_count` (the federated/all-instances total), not
/// `subscriptions_count` (PieFed's local-only count) -- matching v3/v4's own `subscribers` (the
/// federated total) vs `subscribers_local` split; the neutral `Community` has no field for the
/// local-only count, so `subscriptions_count` is intentionally unused, same as v3/v4 drop
/// `subscribers_local`. `comments` reads `post_reply_count` (PieFed's name for "replies to this
/// community's posts," i.e. its comment count).
func neutralCommunity(fromPiefed community: PiefedCommunity, counts: PiefedCommunityCounts) -> Community {
    Community(
        id: community.id,
        name: community.name,
        title: community.title,
        sidebar: community.description,
        apId: community.actor_id,
        iconUrl: community.icon,
        bannerUrl: community.banner,
        visibility: neutralCommunityVisibility(fromPiefedHidden: community.hidden),
        local: community.local,
        nsfw: community.nsfw,
        postingRestrictedToMods: community.restricted_to_mods,
        removed: community.removed,
        deleted: community.deleted,
        publishedAt: piefedDate(community.published) ?? Date(timeIntervalSince1970: 0),
        updatedAt: piefedDate(community.updated),
        subscribers: counts.total_subscriptions_count,
        posts: counts.post_count,
        comments: counts.post_reply_count
    )
}

/// Maps PieFed's plain `hidden: Bool` to the neutral `CommunityVisibility`.
///
/// PieFed sends no `visibility` field at all (Lemmy 0.19 requires one) -- only `hidden`, so this
/// synthesizes the neutral value from that single signal: `hidden == true` maps to `.unlisted`
/// (not shown in public directories), `hidden == false` maps to `._public`. PieFed has no signal
/// equivalent to v4's `.localOnlyPublic`/`.localOnlyPrivate`/`._private`, so this never produces
/// them -- same emulation gap as v3 (see `CommunityV3Mapping.swift`'s
/// `neutralCommunityVisibility(fromV3Hidden:visibility:)`, minus v3's extra `visibility` enum
/// signal, which PieFed doesn't carry).
private func neutralCommunityVisibility(fromPiefedHidden hidden: Bool) -> CommunityVisibility {
    hidden ? .unlisted : ._public
}
