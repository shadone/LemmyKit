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

    /// Whether to show comment / post scores.
    public let show_scores: Bool

    /// Whether to show bot accounts.
    public let show_bot_accounts: Bool

    /// Whether to show read posts.
    public let show_read_posts: Bool

    /// Whether their email has been verified.
    public let email_verified: Bool

    /// Whether their registration application has been accepted.
    public let accepted_application: Bool

    /// Open links in a new tab.
    public let open_links_in_new_tab: Bool

    public let blur_nsfw: Bool

    public let auto_expand: Bool

    /// Whether infinite scroll is enabled.
    public let infinite_scroll_enabled: Bool

    /// Whether the person is an admin.
    public let admin: Bool

    public let post_listing_mode: PostListingMode

    public let totp_2fa_enabled: Bool

    /// Whether to allow keyboard navigation (for browsing and interacting with posts and comments).
    public let enable_keyboard_navigation: Bool

    /// Whether user avatars and inline images in the UI that are gifs should be allowed to play or should be paused
    public let enable_animated_images: Bool

    /// Whether to auto-collapse bot comments.
    public let collapse_bot_comments: Bool

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
        show_scores: Bool,
        show_bot_accounts: Bool,
        show_read_posts: Bool,
        email_verified: Bool,
        accepted_application: Bool,
        open_links_in_new_tab: Bool,
        blur_nsfw: Bool,
        auto_expand: Bool,
        infinite_scroll_enabled: Bool,
        admin: Bool,
        post_listing_mode: PostListingMode,
        totp_2fa_enabled: Bool,
        enable_keyboard_navigation: Bool,
        enable_animated_images: Bool,
        collapse_bot_comments: Bool
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
        self.show_scores = show_scores
        self.show_bot_accounts = show_bot_accounts
        self.show_read_posts = show_read_posts
        self.email_verified = email_verified
        self.accepted_application = accepted_application
        self.open_links_in_new_tab = open_links_in_new_tab
        self.blur_nsfw = blur_nsfw
        self.auto_expand = auto_expand
        self.infinite_scroll_enabled = infinite_scroll_enabled
        self.admin = admin
        self.post_listing_mode = post_listing_mode
        self.totp_2fa_enabled = totp_2fa_enabled
        self.enable_keyboard_navigation = enable_keyboard_navigation
        self.enable_animated_images = enable_animated_images
        self.collapse_bot_comments = collapse_bot_comments
    }
}
