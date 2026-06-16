//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Save settings for the logged-in account.
    ///
    /// All parameters are optional; pass only the fields you want to change.
    ///
    /// - Parameters:
    ///   - showNSFW: whether to display NSFW content.
    ///   - blurNSFW: whether to blur NSFW images instead of hiding them.
    ///   - autoExpand: whether to auto-expand post bodies in the feed.
    ///   - theme: the UI theme name string.
    ///   - defaultSortType: the default sort order for post feeds.
    ///   - defaultListingType: the default listing type (e.g. local, all, subscribed).
    ///   - interfaceLanguage: the BCP 47 language tag for the Lemmy interface language.
    ///   - avatar: URL string for the account's avatar image.
    ///   - banner: URL string for the account's profile banner image.
    ///   - displayName: the display name shown on the account's profile.
    ///   - email: the email address for the account.
    ///   - bio: the profile bio text, in markdown.
    ///   - matrixUserID: the Matrix user ID to display on the profile.
    ///   - showAvatars: whether to show other users' avatars.
    ///   - sendNotificationsToEmail: whether to send mention and reply notifications by email.
    ///   - botAccount: whether to mark this account as a bot.
    ///   - showBotAccounts: whether to show posts and comments from bot accounts.
    ///   - showReadPosts: whether to show already-read posts in feeds.
    ///   - discussionLanguages: the list of language IDs the account wants to see posts in.
    ///   - openLinksInNewTab: whether to open links in a new browser tab.
    ///   - infiniteScrollEnabled: whether to enable infinite scroll in feeds.
    ///   - postListingMode: the post display mode (e.g. card, small card, list).
    ///   - enableKeyboardNavigation: whether to enable keyboard navigation shortcuts.
    ///   - enableAnimatedImages: whether to play animated images.
    ///   - collapseBotComments: whether to collapse bot comments by default.
    ///   - showScores: whether to show vote scores.
    ///   - showUpvotes: whether to show upvote counts.
    ///   - showDownvotes: whether to show downvote counts.
    ///   - showUpvotePercentage: whether to show the upvote percentage.
    /// - Note: requires authentication.
    func saveUserSettings(
        showNSFW: Bool? = nil,
        blurNSFW: Bool? = nil,
        autoExpand: Bool? = nil,
        theme: String? = nil,
        defaultSortType: Components.Schemas.SortType? = nil,
        defaultListingType: Components.Schemas.ListingType? = nil,
        interfaceLanguage: String? = nil,
        avatar: String? = nil,
        banner: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        bio: String? = nil,
        matrixUserID: String? = nil,
        showAvatars: Bool? = nil,
        sendNotificationsToEmail: Bool? = nil,
        botAccount: Bool? = nil,
        showBotAccounts: Bool? = nil,
        showReadPosts: Bool? = nil,
        discussionLanguages: [Components.Schemas.LanguageID]? = nil,
        openLinksInNewTab: Bool? = nil,
        infiniteScrollEnabled: Bool? = nil,
        postListingMode: Components.Schemas.PostListingMode? = nil,
        enableKeyboardNavigation: Bool? = nil,
        enableAnimatedImages: Bool? = nil,
        collapseBotComments: Bool? = nil,
        showScores: Bool? = nil,
        showUpvotes: Bool? = nil,
        showDownvotes: Bool? = nil,
        showUpvotePercentage: Bool? = nil
    ) async throws -> Components.Schemas.SuccessResponse {
        let response: Operations.saveUserSettings.Output
        do {
            response = try await client.saveUserSettings(body: .json(.init(
                show_nsfw: showNSFW,
                blur_nsfw: blurNSFW,
                auto_expand: autoExpand,
                theme: theme,
                default_sort_type: defaultSortType,
                default_listing_type: defaultListingType,
                interface_language: interfaceLanguage,
                avatar: avatar,
                banner: banner,
                display_name: displayName,
                email: email,
                bio: bio,
                matrix_user_id: matrixUserID,
                show_avatars: showAvatars,
                send_notifications_to_email: sendNotificationsToEmail,
                bot_account: botAccount,
                show_bot_accounts: showBotAccounts,
                show_read_posts: showReadPosts,
                discussion_languages: discussionLanguages,
                open_links_in_new_tab: openLinksInNewTab,
                infinite_scroll_enabled: infiniteScrollEnabled,
                post_listing_mode: postListingMode,
                enable_keyboard_navigation: enableKeyboardNavigation,
                enable_animated_images: enableAnimatedImages,
                collapse_bot_comments: collapseBotComments,
                show_scores: showScores,
                show_upvotes: showUpvotes,
                show_downvotes: showDownvotes,
                show_upvote_percentage: showUpvotePercentage
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
