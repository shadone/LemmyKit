//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/local_user.rs

public struct LocalUser: Decodable {
    /// Internal Lemmy user identifier. The same identifier as in JWT sub claim.
    public let id: LocalUserId

    /// The person_id for the local user.
    public let person_id: PersonId

    /// User's email address.
    public let email: String?

    /// Whether to show NSFW content.
    public let show_nsfw: Bool

    /// User's theme. e.g. "browser".
    public let theme: String

    /// The default sort type for the user.
    public let default_sort_type: SortType

    /// The default listing type.
    public let default_listing_type: ListingType

    /// The language of the Lemmy interface.
    public let interface_language: String

    /// Whether to show avatars.
    public let show_avatars: Bool

    /// Whether to send notifications to users email address.
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
    public let totp_2fa_url: LenientUrl?

    public init(
        id: LocalUserId,
        person_id: PersonId,
        email: String? = nil,
        show_nsfw: Bool,
        theme: String,
        default_sort_type: SortType,
        default_listing_type: ListingType,
        interface_language: String,
        show_avatars: Bool,
        send_notifications_to_email: Bool,
        validator_time: Date,
        show_scores: Bool,
        show_bot_accounts: Bool,
        show_read_posts: Bool,
        show_new_post_notifs: Bool,
        email_verified: Bool,
        accepted_application: Bool,
        totp_2fa_url: LenientUrl? = nil
    ) {
        self.id = id
        self.person_id = person_id
        self.email = email
        self.show_nsfw = show_nsfw
        self.theme = theme
        self.default_sort_type = default_sort_type
        self.default_listing_type = default_listing_type
        self.interface_language = interface_language
        self.show_avatars = show_avatars
        self.send_notifications_to_email = send_notifications_to_email
        self.validator_time = validator_time
        self.show_scores = show_scores
        self.show_bot_accounts = show_bot_accounts
        self.show_read_posts = show_read_posts
        self.show_new_post_notifs = show_new_post_notifs
        self.email_verified = email_verified
        self.accepted_application = accepted_application
        self.totp_2fa_url = totp_2fa_url
    }
}
