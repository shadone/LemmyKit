//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/local_user.rs

public struct LocalUser: Decodable {
    public let id: LocalUserId

    /// The person_id for the local user.
    public let person_id: PersonId

    public let email: String?

    /// Whether to show NSFW content.
    public let show_nsfw: Bool

    public let theme: String

    public let default_sort_type: SortType

    public let default_listing_type: ListingType

    public let interface_language: String

    /// Whether to show avatars.
    public let show_avatars: Bool

    public let send_notifications_to_email: Bool

    /// A validation ID used in logging out sessions.
    public let validator_time: Date

    /// Whether to show comment / post scores.
    public let show_scores: Bool

    /// Whether to show bot accounts.
    public let show_bot_accounts: Bool

    /// Whether to show read posts.
    public let show_read_posts: Bool

    /// Whether to show new posts as notifications.
    public let show_new_post_notifs: Bool

    /// Whether their email has been verified.
    public let email_verified: Bool

    /// Whether their registration application has been accepted.
    public let accepted_application: Bool

    /// A URL to add their 2-factor auth.
    public let totp_2fa_url: String?
}
