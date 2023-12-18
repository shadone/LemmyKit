//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/local_site.rs

public struct LocalSite: Decodable {
    public let id: LocalSiteId

    public let site_id: SiteId

    /// True if the site is set up.
    public let site_setup: Bool

    /// Whether downvotes are enabled.
    public let enable_downvotes: Bool

    /// Whether NSFW is enabled.
    public let enable_nsfw: Bool

    /// Whether only admins can create communities.
    public let community_creation_admin_only: Bool

    /// Whether emails are required.
    public let require_email_verification: Bool

    /// An optional registration application questionnaire in markdown.
    public let application_question: String?

    /// Whether the instance is private or public.
    public let private_instance: Bool

    /// The default front-end theme.
    public let default_theme: String

    public let default_post_listing_type: ListingType

    /// An optional legal disclaimer page.
    public let legal_information: String?

    /// Whether to hide mod names on the modlog.
    public let hide_modlog_mod_names: Bool

    /// Whether new applications email admins.
    public let application_email_admins: Bool

    /// An optional regex to filter words.
    public let slur_filter_regex: String?

    /// The max actor name length.
    public let actor_name_max_length: Int32

    /// Whether federation is enabled.
    public let federation_enabled: Bool

    /// Whether captcha is enabled.
    public let captcha_enabled: Bool

    /// The captcha difficulty.
    public let captcha_difficulty: String

    public let published: Date

    public let updated: Date?

    public let registration_mode: RegistrationMode

    /// Whether to email admins on new reports.
    public let reports_email_admins: Bool

    /// Whether to sign outgoing Activitypub fetches with private key of local instance.
    /// Some Fediverse instances and platforms require this.
    public let federation_signed_fetch: Bool

    public init(
        id: LocalSiteId,
        site_id: SiteId,
        site_setup: Bool,
        enable_downvotes: Bool,
        enable_nsfw: Bool,
        community_creation_admin_only: Bool,
        require_email_verification: Bool,
        application_question: String? = nil,
        private_instance: Bool,
        default_theme: String,
        default_post_listing_type: ListingType,
        legal_information: String? = nil,
        hide_modlog_mod_names: Bool,
        application_email_admins: Bool,
        slur_filter_regex: String? = nil,
        actor_name_max_length: Int32,
        federation_enabled: Bool,
        captcha_enabled: Bool,
        captcha_difficulty: String,
        published: Date,
        updated: Date? = nil,
        registration_mode: RegistrationMode,
        reports_email_admins: Bool,
        federation_signed_fetch: Bool
    ) {
        self.id = id
        self.site_id = site_id
        self.site_setup = site_setup
        self.enable_downvotes = enable_downvotes
        self.enable_nsfw = enable_nsfw
        self.community_creation_admin_only = community_creation_admin_only
        self.require_email_verification = require_email_verification
        self.application_question = application_question
        self.private_instance = private_instance
        self.default_theme = default_theme
        self.default_post_listing_type = default_post_listing_type
        self.legal_information = legal_information
        self.hide_modlog_mod_names = hide_modlog_mod_names
        self.application_email_admins = application_email_admins
        self.slur_filter_regex = slur_filter_regex
        self.actor_name_max_length = actor_name_max_length
        self.federation_enabled = federation_enabled
        self.captcha_enabled = captcha_enabled
        self.captcha_difficulty = captcha_difficulty
        self.published = published
        self.updated = updated
        self.registration_mode = registration_mode
        self.reports_email_admins = reports_email_admins
        self.federation_signed_fetch = federation_signed_fetch
    }
}
