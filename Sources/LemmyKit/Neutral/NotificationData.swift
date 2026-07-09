//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The payload of one entry in the unified notification inbox, decoupled from the generated
/// OpenAPI schema. Paired with its metadata in ``NotificationView``.
///
/// Mirrors v4's `NotificationData` (an `anyOf` of four branches, discriminated by
/// `Notification.kind` — see `NotificationV4Mapping.swift`). v3 has no combined notification feed
/// at all; its three separate endpoints (`getReplies`/`getPersonMentions`/`getPrivateMessages`)
/// only ever produce `.comment`/`.comment`/`.privateMessage` respectively, never `.post` or
/// `.modAction` (v4-only kinds — see `NotificationKind`'s doc).
public enum NotificationData: Sendable, Equatable {
    /// A reply or mention: someone's comment. Carries the comment's full ``CommentView``.
    case comment(CommentView)

    /// v4-only: new activity in a followed community. Carries the post's full ``PostView``.
    case post(PostView)

    /// A private message. Carries the message's full ``PrivateMessageView``.
    case privateMessage(PrivateMessageView)

    /// v4-only: a moderation action relevant to the account.
    ///
    /// Deliberately payload-less. v4's `mod_action` notification data wraps a `ModlogView`, but
    /// `ModlogView` has no neutral mapping in LemmyKit yet — Spud (the consumer) doesn't render
    /// modlog entries in the notification inbox in this phase, so there is nothing useful to
    /// carry yet. A `mod_action` notification still decodes fine and maps to this case; a future
    /// phase can add a payload once `ModlogView` gets a neutral mapping.
    case modAction
}
