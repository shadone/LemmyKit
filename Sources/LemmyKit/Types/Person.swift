//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/person.rs

public struct Person: Decodable {
    public let id: PersonId

    public let name: String

    /// A shorter display name.
    public let display_name: String?

    /// A URL for an avatar.
    public let avatar: URL?

    /// Whether the person is banned.
    public let banned: Bool

    public let published: Date

    public let updated: Date?

    /// The federated actor_id.
    public let actor_id: String

    /// An optional bio, in markdown.
    public let bio: String?

    /// Whether the person is local to our site.
    public let local: Bool

    /// A URL for a banner.
    public let banner: URL?

    /// Whether the person is deleted.
    public let deleted: Bool

    /// A matrix id, usually given an @person:matrix.org
    public let matrix_user_id: String?

    /// Whether the person is an admin.
    public let admin: Bool

    /// Whether the person is a bot account.
    public let bot_account: Bool

    /// When their ban, if it exists, expires, if at all.
    public let ban_expires: Date?

    public let instance_id: InstanceId
}
