//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Builds the neutral `MyUser` for a v4 `Components.Schemas.MyUserInfo` (the `GetMyUser`/
/// `GET /account` response body).
///
/// v4 renames `show_scores` to `show_score` (singular) on `LocalUser`; every other consumed field
/// name matches v3's. `follows`/`moderates` are v4's `CommunityFollowerView`/
/// `CommunityModeratorView` lists, mapped through the existing `neutralCommunity(fromV4:)`
/// community adapter.
func neutralMyUser(fromV4 info: LemmyKitV4Generated.Components.Schemas.MyUserInfo) -> MyUser {
    let local = info.local_user_view.local_user
    return MyUser(
        person: neutralPerson(fromV4: info.local_user_view.person),
        localUserId: local.id,
        email: local.email,
        emailVerified: local.email_verified,
        acceptedApplication: local.accepted_application,
        isAdmin: local.admin,
        showNsfw: local.show_nsfw,
        blurNsfw: local.blur_nsfw,
        showScores: local.show_score,
        showBotAccounts: local.show_bot_accounts,
        showReadPosts: local.show_read_posts,
        showAvatars: local.show_avatars,
        defaultListingType: neutralListingType(fromV4: local.default_listing_type),
        follows: info.follows.map { neutralCommunity(fromV4: $0.community) },
        moderates: info.moderates.map(\.community.id)
    )
}

/// Folds v4's differently-cased `ListingType` back into `Lemmy.ListingType` (a v3-shaped alias,
/// see `NeutralVocabulary.swift`) -- the mirror image of `GetPostsNeutral.swift`'s private
/// `v4ListingType(fromNeutral:)`. v4's `.suggested` case has no v3/`Lemmy.ListingType` equivalent
/// (it is a personalized feed recommendation, not a plain scope); it folds to `.All` as the
/// closest "everything" analogue. This is the only lossy direction -- every other case is a
/// direct 1:1 rename.
private func neutralListingType(
    fromV4 type: LemmyKitV4Generated.Components.Schemas.ListingType
) -> Lemmy.ListingType {
    switch type {
    case .all: .All
    case .local: .Local
    case .subscribed: .Subscribed
    case .moderator_view: .ModeratorView
    case .suggested: .All
    }
}
