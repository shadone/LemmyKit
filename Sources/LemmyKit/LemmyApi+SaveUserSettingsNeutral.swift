//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Saves settings for the signed-in account.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). All parameters are optional; pass only the fields you want to change.
    /// This is a minimal, YAGNI-scoped subset of both backends' full settings surface -- see
    /// ``saveUserSettings(showNSFW:blurNSFW:autoExpand:theme:defaultSortType:defaultListingType:interfaceLanguage:avatar:banner:displayName:email:bio:matrixUserID:showAvatars:sendNotificationsToEmail:botAccount:showBotAccounts:showReadPosts:discussionLanguages:openLinksInNewTab:infiniteScrollEnabled:postListingMode:enableKeyboardNavigation:enableAnimatedImages:collapseBotComments:showScores:showUpvotes:showDownvotes:showUpvotePercentage:)``
    /// for the full v3 surface.
    ///
    /// v4 dropped `avatar`/`banner` from this call entirely -- they moved to dedicated
    /// upload/delete endpoints (`UploadUserAvatar`/`DeleteUserAvatar`/`UploadUserBanner`/
    /// `DeleteUserBanner`), which are out of scope here -- so this neutral surface has no avatar/
    /// banner parameters at all rather than silently accepting and dropping them on a v4 backend.
    /// v4 also renamed `show_scores` (plural) to `show_score` (singular); `showScores` folds to
    /// whichever field the target backend has.
    ///
    /// - Parameters:
    ///   - showNSFW: whether to display NSFW content.
    ///   - blurNSFW: whether to blur NSFW images instead of hiding them.
    ///   - defaultSortType: the default sort order for post feeds. Its time window (for a `.top`
    ///     value) is carried separately in `defaultTimeRange`.
    ///   - defaultTimeRange: the time window paired with a `.top` `defaultSortType`, or `nil` for
    ///     no window. On a v3 backend it is fused into the sort case (`.top` + `.week` ->
    ///     `TopWeek`; a nil window -> `TopAll`; an arbitrary window rounds to the nearest bucket --
    ///     see `v3SortType(fromNeutral:timeRange:)`). On v4 it is sent as-is via
    ///     `default_post_time_range_seconds`. Ignored when `defaultSortType` is nil or is not
    ///     `.top`.
    ///   - defaultListingType: the default listing type (e.g. local, all, subscribed).
    ///   - displayName: the display name shown on the account's profile.
    ///   - bio: the profile bio text, in markdown.
    ///   - showScores: whether to show vote scores.
    ///   - showBotAccounts: whether to show posts and comments from bot accounts.
    ///   - showReadPosts: whether to show already-read posts in feeds.
    ///   - showAvatars: whether to show other users' avatars.
    /// - Note: requires authentication.
    func saveUserSettingsNeutral(
        showNSFW: Bool? = nil,
        blurNSFW: Bool? = nil,
        defaultSortType: PostSort? = nil,
        defaultTimeRange: TimeRange? = nil,
        defaultListingType: Lemmy.ListingType? = nil,
        displayName: String? = nil,
        bio: String? = nil,
        showScores: Bool? = nil,
        showBotAccounts: Bool? = nil,
        showReadPosts: Bool? = nil,
        showAvatars: Bool? = nil
    ) async throws {
        switch apiVersion {
        case .v3:
            try await saveUserSettingsNeutralV3(
                showNSFW: showNSFW,
                blurNSFW: blurNSFW,
                defaultSortType: defaultSortType,
                defaultTimeRange: defaultTimeRange,
                defaultListingType: defaultListingType,
                displayName: displayName,
                bio: bio,
                showScores: showScores,
                showBotAccounts: showBotAccounts,
                showReadPosts: showReadPosts,
                showAvatars: showAvatars
            )
        case .v4:
            try await saveUserSettingsNeutralV4(
                showNSFW: showNSFW,
                blurNSFW: blurNSFW,
                defaultSortType: defaultSortType,
                defaultTimeRange: defaultTimeRange,
                defaultListingType: defaultListingType,
                displayName: displayName,
                bio: bio,
                showScores: showScores,
                showBotAccounts: showBotAccounts,
                showReadPosts: showReadPosts,
                showAvatars: showAvatars
            )
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the request-building and response-branching shape of
    /// ``saveUserSettings(showNSFW:blurNSFW:autoExpand:theme:defaultSortType:defaultListingType:interfaceLanguage:avatar:banner:displayName:email:bio:matrixUserID:showAvatars:sendNotificationsToEmail:botAccount:showBotAccounts:showReadPosts:discussionLanguages:openLinksInNewTab:infiniteScrollEnabled:postListingMode:enableKeyboardNavigation:enableAnimatedImages:collapseBotComments:showScores:showUpvotes:showDownvotes:showUpvotePercentage:)``,
    /// restricted to this method's smaller parameter set; every field this method doesn't expose
    /// is left `nil` (unchanged) in the request.
    func saveUserSettingsNeutralV3(
        showNSFW: Bool?,
        blurNSFW: Bool?,
        defaultSortType: PostSort?,
        defaultTimeRange: TimeRange?,
        defaultListingType: Lemmy.ListingType?,
        displayName: String?,
        bio: String?,
        showScores: Bool?,
        showBotAccounts: Bool?,
        showReadPosts: Bool?,
        showAvatars: Bool?
    ) async throws {
        let response: Operations.saveUserSettings.Output
        do {
            response = try await client.saveUserSettings(body: .json(.init(
                show_nsfw: showNSFW,
                blur_nsfw: blurNSFW,
                default_sort_type: defaultSortType.map { v3SortType(fromNeutral: $0, timeRange: defaultTimeRange) },
                default_listing_type: defaultListingType,
                display_name: displayName,
                bio: bio,
                show_avatars: showAvatars,
                show_bot_accounts: showBotAccounts,
                show_read_posts: showReadPosts,
                show_scores: showScores
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

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

    /// v4 path: calls the v4 generated client's `SaveUserSettings` operation (`PUT
    /// /api/v4/account/settings/save`, moved off v3's `PUT /api/v3/user/save_user_settings`),
    /// folding `defaultSortType` via `v4PostSortType(fromNeutral:)` and `defaultListingType` via
    /// `v4ListingType(fromNeutral:)` (shared with `getPostsNeutral`, see `SortMapping.swift`).
    /// v4's `SaveUserSettings` only documents the `ok` response for this operation (no
    /// `unauthorized`/`badRequest` cases like v3), so anything else falls through to
    /// `.undocumented`.
    func saveUserSettingsNeutralV4(
        showNSFW: Bool?,
        blurNSFW: Bool?,
        defaultSortType: PostSort?,
        defaultTimeRange: TimeRange?,
        defaultListingType: Lemmy.ListingType?,
        displayName: String?,
        bio: String?,
        showScores: Bool?,
        showBotAccounts: Bool?,
        showReadPosts: Bool?,
        showAvatars: Bool?
    ) async throws {
        let response: LemmyKitV4Generated.Operations.SaveUserSettings.Output
        do {
            response = try await v4Client.SaveUserSettings(body: .json(.init(
                show_score: showScores,
                show_read_posts: showReadPosts,
                show_bot_accounts: showBotAccounts,
                show_avatars: showAvatars,
                bio: bio,
                display_name: displayName,
                default_post_time_range_seconds: defaultTimeRange?.seconds,
                default_post_sort_type: defaultSortType.map { v4PostSortType(fromNeutral: $0) },
                default_listing_type: defaultListingType.map { v4ListingType(fromNeutral: $0) },
                blur_nsfw: blurNSFW,
                show_nsfw: showNSFW
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
