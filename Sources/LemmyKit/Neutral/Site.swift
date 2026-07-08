//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A Lemmy instance's site info, decoupled from the generated OpenAPI schema.
///
/// This merges v4's `Site` (branding: name/summary/sidebar/icon/banner) with the aggregate
/// counts and creation timestamp v4 moved onto `LocalSite` — there is no separate neutral
/// `LocalSite` entity yet, so those fields live here since this type is what a consumer actually
/// wants when it asks "tell me about this site." Admin-only `LocalSite` configuration (e.g.
/// `legalInformation`, `defaultPostListingType`, `registrationMode`) is deliberately NOT
/// included: no current consumer reads it, and it belongs to that future `LocalSite` type, not
/// to a site's public identity. `version` and the signed-in account's own `MyUser` are
/// deliberately NOT here either — both live only on the `GetSiteResponse` operation result, not
/// on the site itself (see the design doc's "Site / MyUser (my_user split)" section).
public struct Site: Sendable, Equatable, Identifiable {
    /// The server-assigned site id. `Int64` (not `Int32`) for headroom even though v4's `SiteId`
    /// is currently narrower on the wire.
    public let id: Int64

    /// The site's display name.
    public let name: String

    /// A short, one-line summary of the site. This replaces v3's `description` field, which v4
    /// dropped in favor of the shorter `summary` (mirroring the same rename on `Community`).
    public let summary: String?

    /// The site's sidebar, in markdown.
    public let sidebar: String?

    /// The site's icon image URL.
    public let iconUrl: String?

    /// The site's banner image URL.
    public let bannerUrl: String?

    /// The federated ActivityPub id of the site (the instance actor).
    public let apId: String

    /// When the site's local configuration was created. Sourced from v4's `LocalSite`, not the
    /// bare `Site` object — Spud has never read the latter's own `published_at`.
    public let publishedAt: Date

    /// When the site's local configuration was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    /// The total number of posts on the site.
    public let posts: Int64

    /// The total number of comments on the site.
    public let comments: Int64

    /// The total number of communities on the site.
    public let communities: Int64

    /// The total number of user accounts on the site.
    public let users: Int64

    /// The number of users active in the last day.
    public let usersActiveDay: Int64

    /// The number of users active in the last week.
    public let usersActiveWeek: Int64

    /// The number of users active in the last month.
    public let usersActiveMonth: Int64

    /// The number of users active in the last half year.
    public let usersActiveHalfYear: Int64

    public init(
        id: Int64,
        name: String,
        summary: String? = nil,
        sidebar: String? = nil,
        iconUrl: String? = nil,
        bannerUrl: String? = nil,
        apId: String,
        publishedAt: Date,
        updatedAt: Date? = nil,
        posts: Int64,
        comments: Int64,
        communities: Int64,
        users: Int64,
        usersActiveDay: Int64,
        usersActiveWeek: Int64,
        usersActiveMonth: Int64,
        usersActiveHalfYear: Int64
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.sidebar = sidebar
        self.iconUrl = iconUrl
        self.bannerUrl = bannerUrl
        self.apId = apId
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.posts = posts
        self.comments = comments
        self.communities = communities
        self.users = users
        self.usersActiveDay = usersActiveDay
        self.usersActiveWeek = usersActiveWeek
        self.usersActiveMonth = usersActiveMonth
        self.usersActiveHalfYear = usersActiveHalfYear
    }
}
