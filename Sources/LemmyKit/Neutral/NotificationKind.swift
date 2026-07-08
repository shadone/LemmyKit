//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// The kind of an entry in the unified notification inbox, mirroring v4's `NotificationType`.
///
/// `.reply`, `.mention`, and `.privateMessage` have a v3 source (`getReplies`,
/// `getPersonMentions`, `getPrivateMessages` respectively) and the V3 adapter synthesizes them
/// while fanning those three endpoints out and merging them into one timeline. `.subscribed`
/// and `.modAction` are **v4-only**: v3 has no equivalent endpoint, so a v3 backend can never
/// produce a notification of either kind.
public enum NotificationKind: Sendable, Equatable {
    /// The account was mentioned in a post or comment. Has a v3 source (`getPersonMentions`).
    case mention

    /// A reply was posted to the account's own post or comment. Has a v3 source
    /// (`getReplies`).
    case reply

    /// v4-only: new activity in a community the account follows. No v3 source.
    case subscribed

    /// A private message was received. Has a v3 source (`getPrivateMessages`).
    case privateMessage

    /// v4-only: a moderation action relevant to the account occurred. No v3 source.
    case modAction
}
