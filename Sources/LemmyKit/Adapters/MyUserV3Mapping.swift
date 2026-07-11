//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `MyUser` for a v3 `Components.Schemas.MyUserInfo`.
///
/// v3's `local_user_view` bundles the settings (`local_user`), the account's own person, and a
/// `local_user_vote_display_mode`/`counts` this neutral type doesn't carry (see `MyUser.swift`
/// for the full list of deliberately-omitted fields). `follows`/`moderates` are v3's
/// `CommunityFollowerView`/`CommunityModeratorView` lists, mapped through the existing
/// `neutralCommunity(fromV3:)` community adapter.
func neutralMyUser(fromV3 info: Components.Schemas.MyUserInfo) -> MyUser {
    let local = info.local_user_view.local_user
    // v3 fuses the default sort and its top-N window into one `SortType`; un-fuse it back into the
    // neutral `PostSort` + `TimeRange` pair (see `neutralPostSort(fromV3:)`).
    let (defaultSort, defaultTimeRange) = neutralPostSort(fromV3: local.default_sort_type)
    return MyUser(
        person: neutralPerson(fromV3: info.local_user_view.person),
        localUserId: Int64(local.id),
        email: local.email,
        emailVerified: local.email_verified,
        acceptedApplication: local.accepted_application,
        isAdmin: local.admin,
        showNsfw: local.show_nsfw,
        blurNsfw: local.blur_nsfw,
        showScores: local.show_scores,
        showBotAccounts: local.show_bot_accounts,
        showReadPosts: local.show_read_posts,
        showAvatars: local.show_avatars,
        defaultListingType: local.default_listing_type,
        defaultSort: defaultSort,
        defaultTimeRange: defaultTimeRange,
        follows: info.follows.map { neutralCommunity(fromV3: $0.community) },
        moderates: info.moderates.map { Int64($0.community.id) }
    )
}
