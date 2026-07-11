//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's own settings and standing, decoupled from the generated OpenAPI
/// schema.
///
/// Fetched via ``LemmyApi/getMyUserNeutral()``. v4 REMOVED `my_user` from `GetSiteResponse` and
/// moved the signed-in account's info to its own `GET /api/v4/account` operation (`MyUserInfo`);
/// v3 has no equivalent standalone endpoint, so the V3 backend adapter re-fetches `getSite()` and
/// extracts `my_user` (see `LemmyApi+GetMyUserNeutral.swift`).
///
/// This carries the CORE fields Spud's `AccountImporter`/`LemmyService` actually consume -- the
/// local-user preference flags plus enough of `follows`/`moderates` to mirror the account's
/// community relationships -- not the full `LocalUser`/`MyUserInfo` surface. Deliberately omitted
/// (no current consumer reads them): interface language, theme, TOTP status, the donation-
/// notification timestamp, `open_links_in_new_tab`, `auto_expand`/`infinite_scroll_enabled`, and
/// similar UI-only preferences.
///
/// The account's server-side default post sort is carried as the separate `defaultSort` +
/// `defaultTimeRange` pair below. v3 stores this as a single time-bucket-fused `SortType`
/// (`TopDay`/`TopWeek`/...), the same shape `getPosts`' `sort` parameter uses; the V3 adapter
/// un-fuses it via `neutralPostSort(fromV3:)` (the mirror image of `v3SortType(fromNeutral:
/// timeRange:)`). v4 already keeps the sort and its time window apart, so the V4 adapter maps
/// `default_post_sort_type` and `default_post_time_range_seconds` independently.
public struct MyUser: Sendable, Equatable {
    /// The account's own person record.
    public let person: Person

    /// The server-assigned local-user id (distinct from `person.id`).
    public let localUserId: Int64

    /// The account's login email, or `nil` if unset.
    public let email: String?

    /// Whether the account's email has been verified.
    public let emailVerified: Bool

    /// Whether the account's registration application has been accepted. Only meaningful on an
    /// instance that requires applications; `false` otherwise.
    public let acceptedApplication: Bool

    /// Whether the account holds site-wide admin rights.
    public let isAdmin: Bool

    /// Whether the account has opted to see NSFW content.
    public let showNsfw: Bool

    /// Whether NSFW media is blurred until tapped.
    public let blurNsfw: Bool

    /// Whether vote scores are shown on posts/comments.
    public let showScores: Bool

    /// Whether bot accounts are shown in listings.
    public let showBotAccounts: Bool

    /// Whether already-read posts remain visible in listings.
    public let showReadPosts: Bool

    /// Whether avatars are shown throughout the UI.
    public let showAvatars: Bool

    /// The account's default feed scope for new post listings.
    public let defaultListingType: Lemmy.ListingType

    /// The account's server-side default post sort, or `nil` if the server supplies none. On v3
    /// this is un-fused from the account's single bucketed `SortType`; on v4 it comes from
    /// `default_post_sort_type`. A `.top` default pairs with `defaultTimeRange` for its window.
    public let defaultSort: PostSort?

    /// The time window paired with a `.top` `defaultSort`, or `nil` when the default sort carries
    /// no window (every non-`.top` sort, and v3's bucket-less `TopAll`) or the server supplies
    /// none. On v3 this is the window fused into the account's bucketed `SortType`; on v4 it comes
    /// from the separate `default_post_time_range_seconds` field.
    public let defaultTimeRange: TimeRange?

    /// The communities this account follows, as full ``Community`` values rather than bare ids.
    /// Neither backend's `follows` schema (`CommunityFollowerView`) carries a per-follow state
    /// field -- unlike `CommunityActions` elsewhere in the neutral surface, there is no
    /// `FollowState` to expose here; every entry in this list is simply "followed."
    public let follows: [Community]

    /// The ids of communities this account moderates. Bare ids (not full ``Community`` values):
    /// the only consumer (`fetchModerationCapability`) reduces this to a `Set` of ids for a
    /// permission check, never the community's own data.
    public let moderates: [Int64]

    public init(
        person: Person,
        localUserId: Int64,
        email: String? = nil,
        emailVerified: Bool,
        acceptedApplication: Bool,
        isAdmin: Bool,
        showNsfw: Bool,
        blurNsfw: Bool,
        showScores: Bool,
        showBotAccounts: Bool,
        showReadPosts: Bool,
        showAvatars: Bool,
        defaultListingType: Lemmy.ListingType,
        defaultSort: PostSort? = nil,
        defaultTimeRange: TimeRange? = nil,
        follows: [Community] = [],
        moderates: [Int64] = []
    ) {
        self.person = person
        self.localUserId = localUserId
        self.email = email
        self.emailVerified = emailVerified
        self.acceptedApplication = acceptedApplication
        self.isAdmin = isAdmin
        self.showNsfw = showNsfw
        self.blurNsfw = blurNsfw
        self.showScores = showScores
        self.showBotAccounts = showBotAccounts
        self.showReadPosts = showReadPosts
        self.showAvatars = showAvatars
        self.defaultListingType = defaultListingType
        self.defaultSort = defaultSort
        self.defaultTimeRange = defaultTimeRange
        self.follows = follows
        self.moderates = moderates
    }
}
