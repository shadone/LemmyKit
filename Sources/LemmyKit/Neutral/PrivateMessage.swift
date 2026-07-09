//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A private message between two accounts, decoupled from the generated OpenAPI schema.
///
/// This is v4-shaped, matching v4's `PrivateMessage` schema (see `Person.swift`'s doc for the
/// same convention). `deletedByRecipient`/`removed` are v4-only fields with no v3 source (see
/// `PrivateMessageViewV3Mapping.swift`, which defaults both to `false`, the same "no v3 source"
/// pattern as `PersonV3Mapping.swift`'s post/comment counts).
///
/// Deliberately has **no `isRead` field**, even though v3's `PrivateMessage` carries a bare
/// `read` bool. Read state for a private message lives on the wrapping ``Notification/isRead``
/// (fed by v3's `private_message.read` / v4's `notification.read`), not duplicated here — v4
/// itself moved `read` off `PrivateMessage` entirely and onto the unified `Notification`, and
/// this neutral type follows v4's shape rather than re-adding what v4 dropped. This is not an
/// oversight: a v3-backed mapping (`PrivateMessageViewV3Mapping.swift`) explicitly drops
/// `private_message.read` when building this type, feeding it into `Notification.isRead` instead
/// at the call site (`PrivateMessageNotificationV3Mapping.swift`).
public struct PrivateMessage: Sendable, Equatable, Identifiable {
    /// The server-assigned private message id.
    public let id: Int64

    /// The id of the person who sent the message.
    public let creatorId: Int64

    /// The id of the person the message was sent to.
    public let recipientId: Int64

    /// The message content, in markdown.
    public let content: String

    /// Whether the sender has deleted the message.
    public let deleted: Bool

    /// Whether the recipient has deleted the message (recipient-local, doesn't affect the
    /// sender's copy). v4-only — no v3 source, so a v3-backed `PrivateMessage` always has this
    /// `false`.
    public let deletedByRecipient: Bool

    /// Whether the message was removed by an admin. v4-only — no v3 source, so a v3-backed
    /// `PrivateMessage` always has this `false`.
    public let removed: Bool

    /// Whether the message originated on this instance (as opposed to federated in from
    /// elsewhere).
    public let local: Bool

    /// The federated ActivityPub id of the message.
    public let apId: String

    /// When the message was sent.
    public let publishedAt: Date

    /// When the message was last edited, or `nil` if never edited.
    public let updatedAt: Date?

    public init(
        id: Int64,
        creatorId: Int64,
        recipientId: Int64,
        content: String,
        deleted: Bool,
        deletedByRecipient: Bool,
        removed: Bool,
        local: Bool,
        apId: String,
        publishedAt: Date,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.creatorId = creatorId
        self.recipientId = recipientId
        self.content = content
        self.deleted = deleted
        self.deletedByRecipient = deletedByRecipient
        self.removed = removed
        self.local = local
        self.apId = apId
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
    }
}
