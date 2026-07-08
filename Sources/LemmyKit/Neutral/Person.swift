//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A person (user account), decoupled from the generated OpenAPI schema.
///
/// This is v4-shaped: post/comment aggregates are flattened directly onto the person, matching
/// v4's `Person` schema, rather than living on a separate aggregates object reachable only via
/// `PersonView` as in v3. Admin/ban standing (`is_admin`/`banned`/`ban_expires_at`) is
/// intentionally NOT here — v4 keeps those on `PersonView` too (they are still per-viewing-context
/// flags, not flattened), so they belong on the composed view type built on top of this one, not
/// on the bare person.
public struct Person: Sendable, Equatable, Identifiable {
    /// The server-assigned person id. `Int64` (not `Int32`) for headroom even though v4's
    /// `PersonId` is currently narrower on the wire.
    public let id: Int64

    /// The person's short, URL-safe username.
    public let name: String

    /// The person's longer display name, or `nil` if unset.
    public let displayName: String?

    /// The person's avatar image URL, or `nil` if unset.
    public let avatarUrl: String?

    /// The person's banner image URL, or `nil` if unset.
    public let bannerUrl: String?

    /// The person's bio, in markdown, or `nil` if unset.
    public let bio: String?

    /// The federated ActivityPub id of the person.
    public let apId: String

    /// The person's linked Matrix user id, or `nil` if unset.
    public let matrixUserId: String?

    /// Whether the account is marked as a bot.
    public let botAccount: Bool

    /// Whether the account has been deleted by its owner.
    public let deleted: Bool

    /// Whether the person is local to this instance (as opposed to federated in from elsewhere).
    public let local: Bool

    /// When the account was created.
    public let publishedAt: Date

    /// When the account was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    /// The number of posts the person has made.
    public let postCount: Int64

    /// The number of comments the person has made.
    public let commentCount: Int64

    public init(
        id: Int64,
        name: String,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        bannerUrl: String? = nil,
        bio: String? = nil,
        apId: String,
        matrixUserId: String? = nil,
        botAccount: Bool,
        deleted: Bool,
        local: Bool,
        publishedAt: Date,
        updatedAt: Date? = nil,
        postCount: Int64,
        commentCount: Int64
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bannerUrl = bannerUrl
        self.bio = bio
        self.apId = apId
        self.matrixUserId = matrixUserId
        self.botAccount = botAccount
        self.deleted = deleted
        self.local = local
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.postCount = postCount
        self.commentCount = commentCount
    }
}
