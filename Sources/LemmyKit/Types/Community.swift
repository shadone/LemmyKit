//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/community.rs

public struct Community: Decodable {
    public let id: CommunityId

    public let name: String

    /// A longer title, that can contain other characters, and doesn't have to be unique.
    public let title: String

    /// A sidebar / markdown description.
    public let description: String?

    /// Whether the community is removed by a mod.
    public let removed: Bool

    public let published: Date

    public let updated: Date?

    /// Whether the community has been deleted by its creator.
    public let deleted: Bool

    /// Whether its an NSFW community.
    public let nsfw: Bool

    /// The federated actor_id.
    public let actor_id: URL

    /// Whether the community is local.
    public let local: Bool

    /// A URL for an icon.
    public let icon: URL?

    /// A URL for a banner.
    public let banner: URL?

    /// Whether the community is hidden.
    public let hidden: Bool

    /// Whether posting is restricted to mods only.
    public let posting_restricted_to_mods: Bool

    public let instance_id: InstanceId
}
