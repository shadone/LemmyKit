//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A community's visibility/discoverability level.
///
/// v4 replaces v3's plain `hidden: Bool` with this richer set of states. A V3 backend adapter
/// maps `hidden == true` to `.unlisted` and `hidden == false` to `._public`; `.localOnlyPublic`/
/// `.localOnlyPrivate` are v4-only and a v3 backend never produces them.
///
/// Case names prefix `public`/`private` with an underscore because both are Swift keywords —
/// mirroring the same workaround the generated v4 schema
/// (`LemmyKitV4Generated`'s `Components.Schemas.CommunityVisibility`) already uses.
public enum CommunityVisibility: Sendable, Equatable {
    /// Listed in public community directories and joinable by anyone.
    case _public

    /// Joinable by anyone, but not shown in public community listings. Matches v3's
    /// `hidden == true`.
    case unlisted

    /// Content is visible to everyone, but only local accounts may join or post.
    case localOnlyPublic

    /// Content and membership are both restricted to accounts local to this instance.
    case localOnlyPrivate

    /// Joining requires moderator approval, and posts are not federated to non-members.
    case _private
}

/// A community, decoupled from the generated OpenAPI schema.
///
/// This is v4-shaped: subscriber/post/comment aggregates are flattened directly onto the
/// community, matching v4's `Community` schema, rather than living on a separate aggregates
/// object as in v3. A V3 backend adapter reads them from `counts` instead. Per-viewer state
/// (follow/block/moderator standing) is intentionally NOT here — it lives on the
/// `communityActions` carried by the composed `CommunityView` (built on top of this type), since
/// it depends on who is asking, not on the community itself.
public struct Community: Sendable, Equatable, Identifiable {
    /// The server-assigned community id. `Int64` (not `Int32`) for headroom even though v4's
    /// `CommunityId` is currently narrower on the wire.
    public let id: Int64

    /// The community's short, URL-safe name (e.g. `"technology"`).
    public let name: String

    /// The community's longer display title, which may contain characters `name` doesn't allow
    /// and need not be unique. `nil` for a bare/federated stub.
    public let title: String?

    /// The community's sidebar, in markdown.
    public let sidebar: String?

    /// The federated ActivityPub id of the community.
    public let apId: String

    /// The community's icon image URL.
    public let iconUrl: String?

    /// The community's banner image URL.
    public let bannerUrl: String?

    /// The community's visibility/discoverability level.
    public let visibility: CommunityVisibility

    /// Whether the community is local to this instance (as opposed to federated in from
    /// elsewhere).
    public let local: Bool

    /// Whether the community is marked NSFW.
    public let nsfw: Bool

    /// Whether posting in the community is restricted to its moderators.
    public let postingRestrictedToMods: Bool

    /// Whether the community has been removed by a moderator.
    public let removed: Bool

    /// Whether the community has been deleted by its creator.
    public let deleted: Bool

    /// When the community was created.
    public let publishedAt: Date

    /// When the community was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    /// The number of subscribers (followers) the community has.
    public let subscribers: Int64

    /// The number of posts in the community.
    public let posts: Int64

    /// The number of comments across all of the community's posts.
    public let comments: Int64

    public init(
        id: Int64,
        name: String,
        title: String? = nil,
        sidebar: String? = nil,
        apId: String,
        iconUrl: String? = nil,
        bannerUrl: String? = nil,
        visibility: CommunityVisibility,
        local: Bool,
        nsfw: Bool,
        postingRestrictedToMods: Bool,
        removed: Bool,
        deleted: Bool,
        publishedAt: Date,
        updatedAt: Date? = nil,
        subscribers: Int64,
        posts: Int64,
        comments: Int64
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.sidebar = sidebar
        self.apId = apId
        self.iconUrl = iconUrl
        self.bannerUrl = bannerUrl
        self.visibility = visibility
        self.local = local
        self.nsfw = nsfw
        self.postingRestrictedToMods = postingRestrictedToMods
        self.removed = removed
        self.deleted = deleted
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.subscribers = subscribers
        self.posts = posts
        self.comments = comments
    }
}
