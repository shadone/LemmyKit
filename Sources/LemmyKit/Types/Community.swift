//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/community.rs

public struct Community: Decodable {
    /// Community identifier. The identifier is local to this instance.
    public let id: CommunityId

    /// The unique name of the community.
    ///
    /// E.g. `mylittlepony`
    public let name: String

    /// A longer title, that can contain other characters, and doesn't have to be unique.
    ///
    /// E.g. `MLP: Friendship is Magic Reddit Community`
    public let title: String

    /// A sidebar / markdown description.
    public let description: String?

    /// Whether the community is removed by a mod.
    public let removed: Bool

    /// The date community was created.
    public let published: Date

    /// The date community info was last updated.
    public let updated: Date?

    /// Whether the community has been deleted by its creator.
    public let deleted: Bool

    /// Whether it is an NSFW community.
    public let nsfw: Bool

    /// The federated actor_id.
    ///
    /// E.g. `https://lemmit.online/c/mylittlepony`
    public let actor_id: URL

    /// Whether the community is local.
    public let local: Bool

    /// A URL for an icon.
    public let icon: LenientUrl?

    /// A URL for a banner.
    public let banner: LenientUrl?

    /// Whether the community is hidden.
    public let hidden: Bool

    /// Whether posting is restricted to mods only.
    public let posting_restricted_to_mods: Bool

    public let instance_id: InstanceId

    public init(
        id: CommunityId,
        name: String,
        title: String,
        description: String? = nil,
        removed: Bool,
        published: Date,
        updated: Date? = nil,
        deleted: Bool,
        nsfw: Bool,
        actor_id: URL,
        local: Bool,
        icon: LenientUrl? = nil,
        banner: LenientUrl? = nil,
        hidden: Bool,
        posting_restricted_to_mods: Bool,
        instance_id: InstanceId
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.removed = removed
        self.published = published
        self.updated = updated
        self.deleted = deleted
        self.nsfw = nsfw
        self.actor_id = actor_id
        self.local = local
        self.icon = icon
        self.banner = banner
        self.hidden = hidden
        self.posting_restricted_to_mods = posting_restricted_to_mods
        self.instance_id = instance_id
    }
}
