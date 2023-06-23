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

    /// The number of concurrent federation http workers.
    public let federation_worker_count: Int32

    /// Whether captcha is enabled.
    public let captcha_enabled: Bool

    /// The captcha difficulty.
    public let captcha_difficulty: String

    public let published: Date

    public let updated: Date?

    public let registration_mode: RegistrationMode

    /// Whether to email admins on new reports.
    public let reports_email_admins: Bool
}
