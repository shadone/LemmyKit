//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Create the site. Only the `name` is required; all other settings are
    /// optional and default to the server's choices.
    func createSite(
        name: Swift.String,
        sidebar: Swift.String? = nil,
        description: Swift.String? = nil,
        icon: Swift.String? = nil,
        banner: Swift.String? = nil,
        enableDownvotes: Swift.Bool? = nil,
        enableNSFW: Swift.Bool? = nil,
        communityCreationAdminOnly: Swift.Bool? = nil,
        requireEmailVerification: Swift.Bool? = nil,
        applicationQuestion: Swift.String? = nil,
        privateInstance: Swift.Bool? = nil,
        defaultTheme: Swift.String? = nil,
        defaultPostListingType: Components.Schemas.ListingType? = nil,
        defaultSortType: Components.Schemas.SortType? = nil,
        legalInformation: Swift.String? = nil,
        applicationEmailAdmins: Swift.Bool? = nil,
        hideModlogModNames: Swift.Bool? = nil,
        discussionLanguages: [Components.Schemas.LanguageID]? = nil,
        slurFilterRegex: Swift.String? = nil,
        actorNameMaxLength: Swift.Int32? = nil,
        rateLimitMessage: Swift.Int32? = nil,
        rateLimitMessagePerSecond: Swift.Int32? = nil,
        rateLimitPost: Swift.Int32? = nil,
        rateLimitPostPerSecond: Swift.Int32? = nil,
        rateLimitRegister: Swift.Int32? = nil,
        rateLimitRegisterPerSecond: Swift.Int32? = nil,
        rateLimitImage: Swift.Int32? = nil,
        rateLimitImagePerSecond: Swift.Int32? = nil,
        rateLimitComment: Swift.Int32? = nil,
        rateLimitCommentPerSecond: Swift.Int32? = nil,
        rateLimitSearch: Swift.Int32? = nil,
        rateLimitSearchPerSecond: Swift.Int32? = nil,
        federationEnabled: Swift.Bool? = nil,
        federationDebug: Swift.Bool? = nil,
        captchaEnabled: Swift.Bool? = nil,
        captchaDifficulty: Swift.String? = nil,
        allowedInstances: [Swift.String]? = nil,
        blockedInstances: [Swift.String]? = nil,
        taglines: [Swift.String]? = nil,
        registrationMode: Components.Schemas.RegistrationMode? = nil,
        contentWarning: Swift.String? = nil,
        defaultPostListingMode: Components.Schemas.PostListingMode? = nil
    ) async throws -> Components.Schemas.SiteResponse {
        let response: Operations.createSite.Output
        do {
            response = try await client.createSite(body: .json(.init(
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
                taglines: taglines,
                registration_mode: registrationMode,
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
