//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/person.rs

public struct Person: Decodable {
    /// Person identifier. The identifier is local to this instance.
    public let id: PersonId

    /// Username (aka nickname aka short users' name). e.g. "helloworld"
    public let name: String

    /// A display name for the user. e.g. "Hello World!"
    public let display_name: String?

    /// A URL for an avatar.
    public let avatar: LenientUrl?

    /// Whether the person is banned.
    public let banned: Bool

    /// The account creation date.
    public let published: Date

    public let updated: Date?

    /// The federated actor_id.
    /// e.g. `https://discuss.tchncs.de/u/milan`
    public let actor_id: URL

    /// An optional bio, in markdown.
    public let bio: String?

    /// Whether the person is local to our site.
    public let local: Bool

    /// A URL for a banner.
    public let banner: LenientUrl?

    /// Whether the person is deleted.
    public let deleted: Bool

    /// A matrix id, usually given an @person:matrix.org
    public let matrix_user_id: String?

    /// Whether the person is a bot account.
    public let bot_account: Bool

    /// When their ban, if it exists, expires, if at all.
    public let ban_expires: Date?

    /// Which instance the person belongs to.
    public let instance_id: InstanceId

    public init(
        id: PersonId,
        name: String,
        display_name: String? = nil,
        avatar: LenientUrl? = nil,
        banned: Bool,
        published: Date,
        updated: Date? = nil,
        actor_id: URL,
        bio: String? = nil,
        local: Bool,
        banner: LenientUrl? = nil,
        deleted: Bool,
        matrix_user_id: String? = nil,
        bot_account: Bool,
        ban_expires: Date? = nil,
        instance_id: InstanceId
    ) {
        self.id = id
        self.name = name
        self.display_name = display_name
        self.avatar = avatar
        self.banned = banned
        self.published = published
        self.updated = updated
        self.actor_id = actor_id
        self.bio = bio
        self.local = local
        self.banner = banner
        self.deleted = deleted
        self.matrix_user_id = matrix_user_id
        self.bot_account = bot_account
        self.ban_expires = ban_expires
        self.instance_id = instance_id
    }
}
