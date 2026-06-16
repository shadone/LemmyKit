//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Edit the site. Every field is optional; pass only the settings you want
    /// to change.
    ///
    /// - Note: admin only.
    ///
    /// - Parameters:
    ///   - name: the human-readable site name.
    ///   - sidebar: sidebar markdown text.
    ///   - description: short site description.
    ///   - icon: url of the site icon image.
    ///   - banner: url of the site banner image.
    ///   - enableDownvotes: whether downvoting is allowed site-wide.
    ///   - enableNSFW: whether NSFW content is allowed to be posted.
    ///   - communityCreationAdminOnly: when true, only admins may create communities.
    ///   - requireEmailVerification: whether new accounts must verify their email address.
    ///   - applicationQuestion: markdown prompt shown to users applying for an account.
    ///   - privateInstance: when true, the instance is not publicly browsable without an account.
    ///   - defaultTheme: name of the default UI theme.
    ///   - defaultPostListingType: default listing scope for post feeds (all, local, subscribed).
    ///   - defaultSortType: default sort order for post feeds.
    ///   - legalInformation: markdown text for the site's legal information page.
    ///   - applicationEmailAdmins: whether admins receive email notifications for new applications.
    ///   - hideModlogModNames: when true, moderator names are hidden in the public modlog.
    ///   - discussionLanguages: list of language ids enabled for discussions on this site.
    ///   - slurFilterRegex: regular expression used to filter disallowed words from content.
    ///   - actorNameMaxLength: maximum character length for new actor (user/community) names.
    ///   - rateLimitMessage: max private messages allowed per rate-limit window.
    ///   - rateLimitMessagePerSecond: duration in seconds of the private-message rate-limit window.
    ///   - rateLimitPost: max posts allowed per rate-limit window.
    ///   - rateLimitPostPerSecond: duration in seconds of the post rate-limit window.
    ///   - rateLimitRegister: max account registrations allowed per rate-limit window.
    ///   - rateLimitRegisterPerSecond: duration in seconds of the registration rate-limit window.
    ///   - rateLimitImage: max image uploads allowed per rate-limit window.
    ///   - rateLimitImagePerSecond: duration in seconds of the image rate-limit window.
    ///   - rateLimitComment: max comments allowed per rate-limit window.
    ///   - rateLimitCommentPerSecond: duration in seconds of the comment rate-limit window.
    ///   - rateLimitSearch: max search requests allowed per rate-limit window.
    ///   - rateLimitSearchPerSecond: duration in seconds of the search rate-limit window.
    ///   - federationEnabled: whether the instance federates with other instances.
    ///   - federationDebug: whether verbose federation debug logging is enabled.
    ///   - captchaEnabled: whether captcha challenges are required at registration.
    ///   - captchaDifficulty: difficulty level of the captcha (e.g. "easy", "medium", "hard").
    ///   - allowedInstances: allowlist of remote instance hostnames to federate with; nil allows all.
    ///   - blockedInstances: blocklist of remote instance hostnames to refuse federation with.
    ///   - blockedURLs: list of urls whose linked content is blocked from being posted.
    ///   - taglines: list of rotating tagline strings shown on the site.
    ///   - registrationMode: who is permitted to register (open, requires application, closed).
    ///   - reportsEmailAdmins: whether admins receive email notifications for new content reports.
    ///   - contentWarning: site-wide content warning message shown to visitors.
    ///   - defaultPostListingMode: default post display density (list, card, small card).
    func editSite(
        name: String? = nil,
        sidebar: String? = nil,
        description: String? = nil,
        icon: String? = nil,
        banner: String? = nil,
        enableDownvotes: Bool? = nil,
        enableNSFW: Bool? = nil,
        communityCreationAdminOnly: Bool? = nil,
        requireEmailVerification: Bool? = nil,
        applicationQuestion: String? = nil,
        privateInstance: Bool? = nil,
        defaultTheme: String? = nil,
        defaultPostListingType: Components.Schemas.ListingType? = nil,
        defaultSortType: Components.Schemas.SortType? = nil,
        legalInformation: String? = nil,
        applicationEmailAdmins: Bool? = nil,
        hideModlogModNames: Bool? = nil,
        discussionLanguages: [Components.Schemas.LanguageID]? = nil,
        slurFilterRegex: String? = nil,
        actorNameMaxLength: Int32? = nil,
        rateLimitMessage: Int32? = nil,
        rateLimitMessagePerSecond: Int32? = nil,
        rateLimitPost: Int32? = nil,
        rateLimitPostPerSecond: Int32? = nil,
        rateLimitRegister: Int32? = nil,
        rateLimitRegisterPerSecond: Int32? = nil,
        rateLimitImage: Int32? = nil,
        rateLimitImagePerSecond: Int32? = nil,
        rateLimitComment: Int32? = nil,
        rateLimitCommentPerSecond: Int32? = nil,
        rateLimitSearch: Int32? = nil,
        rateLimitSearchPerSecond: Int32? = nil,
        federationEnabled: Bool? = nil,
        federationDebug: Bool? = nil,
        captchaEnabled: Bool? = nil,
        captchaDifficulty: String? = nil,
        allowedInstances: [String]? = nil,
        blockedInstances: [String]? = nil,
        blockedURLs: [String]? = nil,
        taglines: [String]? = nil,
        registrationMode: Components.Schemas.RegistrationMode? = nil,
        reportsEmailAdmins: Bool? = nil,
        contentWarning: String? = nil,
        defaultPostListingMode: Components.Schemas.PostListingMode? = nil
    ) async throws -> Components.Schemas.SiteResponse {
        let response: Operations.editSite.Output
        do {
            response = try await client.editSite(body: .json(.init(
                name: name,
                sidebar: sidebar,
                description: description,
                icon: icon,
                banner: banner,
                enable_downvotes: enableDownvotes,
                enable_nsfw: enableNSFW,
                community_creation_admin_only: communityCreationAdminOnly,
                require_email_verification: requireEmailVerification,
                application_question: applicationQuestion,
                private_instance: privateInstance,
                default_theme: defaultTheme,
                default_post_listing_type: defaultPostListingType,
                default_sort_type: defaultSortType,
                legal_information: legalInformation,
                application_email_admins: applicationEmailAdmins,
                hide_modlog_mod_names: hideModlogModNames,
                discussion_languages: discussionLanguages,
                slur_filter_regex: slurFilterRegex,
                actor_name_max_length: actorNameMaxLength,
                rate_limit_message: rateLimitMessage,
                rate_limit_message_per_second: rateLimitMessagePerSecond,
                rate_limit_post: rateLimitPost,
                rate_limit_post_per_second: rateLimitPostPerSecond,
                rate_limit_register: rateLimitRegister,
                rate_limit_register_per_second: rateLimitRegisterPerSecond,
                rate_limit_image: rateLimitImage,
                rate_limit_image_per_second: rateLimitImagePerSecond,
                rate_limit_comment: rateLimitComment,
                rate_limit_comment_per_second: rateLimitCommentPerSecond,
                rate_limit_search: rateLimitSearch,
                rate_limit_search_per_second: rateLimitSearchPerSecond,
                federation_enabled: federationEnabled,
                federation_debug: federationDebug,
                captcha_enabled: captchaEnabled,
                captcha_difficulty: captchaDifficulty,
                allowed_instances: allowedInstances,
                blocked_instances: blockedInstances,
                blocked_urls: blockedURLs,
                taglines: taglines,
                registration_mode: registrationMode,
                reports_email_admins: reportsEmailAdmins,
                content_warning: contentWarning,
                default_post_listing_mode: defaultPostListingMode
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
