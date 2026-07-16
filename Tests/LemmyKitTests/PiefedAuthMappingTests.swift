//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import Testing
@testable import LemmyKit

/// Behavioral coverage for the Phase-2 PieFed my-user/inbox/DM/person adapters:
/// `Sources/LemmyKit/Adapters/MyUserPiefedMapping.swift`, `UnreadCountsPiefedMapping.swift`,
/// `PrivateMessagePiefedMapping.swift`, `NotificationPiefedMapping.swift`,
/// `PersonDetailsPiefedMapping.swift`.
///
/// Like `PiefedMappingTests` (the Phase-1 sibling), assertions are pinned against the real Task-1
/// fixtures (`Tests/LemmyKitTests/Fixtures/piefed-*.json`) decoded through the hand-written
/// `Piefed*` wire models, not tautological placeholders. A few branches the captured fixtures don't
/// exercise (an unrecognized/nil `default_listing_type`/`default_sort_type`, a read
/// notification/private-message, a mixed post+comment interleave) are covered with directly
/// constructed `Piefed*` values instead, following the same factory pattern `PiefedMappingTests`
/// uses.
struct PiefedAuthMappingTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private var decoder: JSONDecoder { JSONDecoder() }

    // MARK: - neutralMyUser(fromPiefed:)

    @Test
    func myUserMapsFromUserMeFixtureWithEmptyFollows() throws {
        let resp = try decoder.decode(PiefedUserMeResponse.self, from: fixture("piefed-user_me"))
        let myUser = neutralMyUser(fromPiefed: resp)

        #expect(myUser.person.name == "mark")
        // localUserId comes from local_user_view.person.id, NOT local_user.id (PieFed's
        // local_user carries no id field at all).
        #expect(myUser.localUserId == 10)
        // `user/me`'s follows array is observed empty even while subscribed -- see this
        // response's doc.
        #expect(myUser.follows.isEmpty)
        #expect(myUser.moderates.isEmpty)

        // Settings PieFed actually carries under a matching name.
        #expect(myUser.showNsfw == false)
        #expect(myUser.showBotAccounts == true)
        #expect(myUser.showReadPosts == true)
        #expect(myUser.showScores == true)
        #expect(myUser.defaultListingType == .Subscribed)
        #expect(myUser.defaultSort == .hot)
        #expect(myUser.defaultTimeRange == nil)

        // Settings with no PieFed source at all -- documented defaults.
        #expect(myUser.email == nil)
        #expect(myUser.emailVerified == false)
        #expect(myUser.acceptedApplication == false)
        #expect(myUser.isAdmin == false)
        #expect(myUser.blurNsfw == false)
        #expect(myUser.showAvatars == false)
    }

    @Test
    func myUserMapsPopulatedFollowsFromSiteEmbed() throws {
        let resp = try decoder.decode(PiefedGetSiteResponse.self, from: fixture("piefed-site_authed"))
        let myUser = try #require(resp.my_user, "authed /site must carry the my_user embed")
        let neutral = neutralMyUser(fromPiefed: myUser)

        // Unlike `user/me`, the `my_user` embed's follows reflects the live subscription.
        #expect(neutral.follows.count == 1)
        #expect(neutral.follows.first?.name == "piefedtest")
    }

    @Test
    func myUserDefaultListingTypeFallsBackToAllWhenNilOrUnrecognized() {
        let nilCase = Self.makeUserMeResponse(defaultListingType: nil)
        let unrecognizedCase = Self.makeUserMeResponse(defaultListingType: "Popular")

        #expect(neutralMyUser(fromPiefed: nilCase).defaultListingType == .All)
        #expect(neutralMyUser(fromPiefed: unrecognizedCase).defaultListingType == .All)
    }

    @Test
    func myUserDefaultListingTypeMapsRecognizedValues() {
        #expect(neutralMyUser(fromPiefed: Self.makeUserMeResponse(defaultListingType: "Local")).defaultListingType == .Local)
        #expect(
            neutralMyUser(fromPiefed: Self.makeUserMeResponse(defaultListingType: "ModeratorView")).defaultListingType == .ModeratorView
        )
    }

    @Test
    func myUserDefaultSortFallsBackToNilWhenNilOrUnrecognized() {
        let nilCase = Self.makeUserMeResponse(defaultSortType: nil)
        let unrecognizedCase = Self.makeUserMeResponse(defaultSortType: "NotARealSort")

        let nilNeutral = neutralMyUser(fromPiefed: nilCase)
        #expect(nilNeutral.defaultSort == nil)
        #expect(nilNeutral.defaultTimeRange == nil)

        let unrecognizedNeutral = neutralMyUser(fromPiefed: unrecognizedCase)
        #expect(unrecognizedNeutral.defaultSort == nil)
        #expect(unrecognizedNeutral.defaultTimeRange == nil)
    }

    @Test
    func myUserDefaultSortUnfusesTopBucket() {
        let neutral = neutralMyUser(fromPiefed: Self.makeUserMeResponse(defaultSortType: "TopWeek"))
        #expect(neutral.defaultSort == .top)
        #expect(neutral.defaultTimeRange == .week)
    }

    // MARK: - neutralUnreadCounts(fromPiefed:)

    @Test
    func unreadCountsMapsZeroFixture() throws {
        let resp = try decoder.decode(PiefedUnreadCountResponse.self, from: fixture("piefed-unread_count"))
        let counts = neutralUnreadCounts(fromPiefed: resp)

        #expect(counts.total == 0)
        #expect(counts.replies == 0)
        #expect(counts.mentions == 0)
        #expect(counts.privateMessages == 0)
    }

    @Test
    func unreadCountsSumsAllFourKindsIncludingOther() {
        let resp = PiefedUnreadCountResponse(mentions: 2, replies: 3, private_messages: 4, other: 5)
        let counts = neutralUnreadCounts(fromPiefed: resp)

        // `other` folds into `total` (no neutral field of its own for it) but is not exposed as
        // its own breakdown field.
        #expect(counts.total == 14)
        #expect(counts.replies == 3)
        #expect(counts.mentions == 2)
        #expect(counts.privateMessages == 4)
    }

    // MARK: - neutralPrivateMessageView(fromPiefed:) / neutralPrivateMessageListItem(fromPiefed:)

    @Test
    func privateMessageViewMapsFixture() throws {
        let view = try decoder.decode(PiefedPrivateMessageView.self, from: fixture("piefed-pm_view"))
        let neutral = neutralPrivateMessageView(fromPiefed: view)

        #expect(neutral.privateMessage.content == "Synthetic DM body for fixture decoding")
        #expect(neutral.privateMessage.recipientId == 10)
        #expect(neutral.privateMessage.creatorId == 1)
        #expect(neutral.privateMessage.apId == "https://piefed1.lemmy.ddenis.info/private_message/1")
        #expect(neutral.privateMessage.deleted == false)
        #expect(neutral.privateMessage.local == true)
        // v4-only fields with no PieFed source.
        #expect(neutral.privateMessage.deletedByRecipient == false)
        #expect(neutral.privateMessage.removed == false)
        #expect(neutral.creator.name == "admin")
        #expect(neutral.recipient.name == "mark")
    }

    @Test
    func privateMessageListItemCarriesUnreadFromFixture() throws {
        let view = try decoder.decode(PiefedPrivateMessageView.self, from: fixture("piefed-pm_view"))
        let item = neutralPrivateMessageListItem(fromPiefed: view)

        // The fixture's private_message.read is false.
        #expect(item.isRead == false)
        #expect(item.view.privateMessage.id == neutralPrivateMessageView(fromPiefed: view).privateMessage.id)
    }

    @Test
    func privateMessageListItemIsReadReflectsReadTrue() throws {
        let view = try decoder.decode(PiefedPrivateMessageView.self, from: fixture("piefed-pm_view"))
        let readMessage = PiefedPrivateMessage(
            id: view.private_message.id,
            creator_id: view.private_message.creator_id,
            recipient_id: view.private_message.recipient_id,
            content: view.private_message.content,
            read: true,
            published: view.private_message.published,
            deleted: view.private_message.deleted,
            ap_id: view.private_message.ap_id,
            local: view.private_message.local
        )
        let readView = PiefedPrivateMessageView(
            private_message: readMessage,
            creator: view.creator,
            recipient: view.recipient,
            conversation_id: view.conversation_id
        )

        #expect(neutralPrivateMessageListItem(fromPiefed: readView).isRead == true)
    }

    // MARK: - neutralNotificationView(fromPiefedReply:kind:)

    @Test
    func notificationViewMapsReplyItemFixtureAsReplyKind() throws {
        let item = try decoder.decode(PiefedReplyItem.self, from: fixture("piefed-replies_item"))
        let view = neutralNotificationView(fromPiefedReply: item, kind: .reply)

        #expect(view.notification.kind == .reply)
        #expect(view.notification.id == 1)
        #expect(view.notification.isRead == false)
        #expect(view.notification.publishedAt != nil)

        guard case let .comment(commentView) = view.data else {
            Issue.record("expected .comment payload")
            return
        }
        #expect(commentView.comment.content == "Spud fixture capture - will be deleted")
        #expect(commentView.creator.name == "admin")
        #expect(commentView.community.name == "piefedtest")
    }

    @Test
    func notificationViewPassesThroughMentionKind() throws {
        let item = try decoder.decode(PiefedReplyItem.self, from: fixture("piefed-replies_item"))
        let view = neutralNotificationView(fromPiefedReply: item, kind: .mention)

        #expect(view.notification.kind == .mention)
    }

    @Test
    func notificationViewIsReadReflectsCommentReplyReadTrue() throws {
        let item = try decoder.decode(PiefedReplyItem.self, from: fixture("piefed-replies_item"))
        let readReply = PiefedCommentReply(
            id: item.comment_reply.id,
            read: true,
            comment_id: item.comment_reply.comment_id,
            published: item.comment_reply.published,
            recipient_id: item.comment_reply.recipient_id
        )
        let readItem = PiefedReplyItem(
            comment: item.comment,
            comment_reply: readReply,
            community: item.community,
            counts: item.counts,
            creator: item.creator,
            post: item.post,
            recipient: item.recipient,
            my_vote: item.my_vote,
            saved: item.saved,
            subscribed: item.subscribed,
            activity_alert: item.activity_alert,
            creator_banned_from_community: item.creator_banned_from_community,
            creator_blocked: item.creator_blocked,
            creator_is_admin: item.creator_is_admin,
            creator_is_moderator: item.creator_is_moderator,
            distinguished: item.distinguished
        )

        #expect(neutralNotificationView(fromPiefedReply: readItem, kind: .reply).notification.isRead == true)
    }

    // MARK: - neutralPersonDetails(fromPiefed:) / neutralPersonContentPage(fromPiefed:)

    @Test
    func personDetailsMapsFixture() throws {
        let resp = try decoder.decode(PiefedPersonDetailsResponse.self, from: fixture("piefed-person_details"))
        let details = neutralPersonDetails(fromPiefed: resp)

        #expect(details.personView.person.name == "mark")
        #expect(details.personView.isAdmin == false)
        #expect(details.moderates == [4])
    }

    @Test
    func personContentPageMapsFixtureAsSinglePage() throws {
        let resp = try decoder.decode(PiefedPersonDetailsResponse.self, from: fixture("piefed-person_details"))
        let page = neutralPersonContentPage(fromPiefed: resp)

        #expect(page.items.count == 1)
        #expect(page.items.first?.comment != nil)
        #expect(page.items.first?.post == nil)
        #expect(page.nextPage == nil)
        #expect(page.prevPage == nil)
    }

    @Test
    func personContentPageInterleavesPostsAndCommentsByRecency() {
        let olderPost = Self.makePostView(id: 1, published: "2026-01-01T00:00:00.000000Z")
        let newerComment = Self.makeCommentView(id: 2, published: "2026-06-01T00:00:00.000000Z")
        let response = PiefedPersonDetailsResponse(
            person_view: Self.makePersonView(),
            comments: [newerComment],
            posts: [olderPost],
            moderates: nil,
            site: nil
        )

        let page = neutralPersonContentPage(fromPiefed: response)

        #expect(page.items.count == 2)
        // Newer comment sorts first (descending by publishedAt).
        #expect(page.items.first?.comment != nil)
        #expect(page.items.last?.post != nil)
    }

    // MARK: - Factories

    private static func makePerson(id: Int64 = 10, userName: String = "mark") -> PiefedPerson {
        PiefedPerson(
            id: id,
            user_name: userName,
            title: userName,
            banned: false,
            deleted: false,
            bot: false,
            published: "2026-07-14T00:00:00.000000Z",
            actor_id: "https://example.com/u/\(userName)",
            local: true,
            instance_id: 1,
            avatar: nil,
            banner: nil,
            about: nil,
            about_html: nil,
            extra_fields: [],
            flair: nil
        )
    }

    private static func makeLocalUser(
        defaultListingType: String? = "Subscribed",
        defaultSortType: String? = "Hot"
    ) -> PiefedLocalUser {
        PiefedLocalUser(
            accept_private_messages: nil,
            bot_visibility: nil,
            ai_visibility: nil,
            community_keyword_filter: nil,
            default_comment_sort_type: nil,
            default_listing_type: defaultListingType,
            default_sort_type: defaultSortType,
            email_unread: nil,
            federate_votes: nil,
            feed_auto_follow: nil,
            feed_auto_leave: nil,
            hide_low_quality: nil,
            indexable: nil,
            newsletter: nil,
            nsfl_visibility: nil,
            nsfw_visibility: nil,
            reply_collapse_threshold: nil,
            reply_hide_threshold: nil,
            searchable: nil,
            show_bot_accounts: true,
            show_nsfl: nil,
            show_nsfw: false,
            show_read_posts: true,
            show_scores: true,
            manually_approves_followers: nil
        )
    }

    private static func makeUserMeResponse(
        defaultListingType: String? = "Subscribed",
        defaultSortType: String? = "Hot"
    ) -> PiefedUserMeResponse {
        PiefedUserMeResponse(
            local_user_view: PiefedLocalUserView(
                local_user: makeLocalUser(defaultListingType: defaultListingType, defaultSortType: defaultSortType),
                person: makePerson(),
                counts: PiefedPersonCounts(comment_count: 0, person_id: 10, post_count: 0)
            ),
            follows: [],
            moderates: [],
            community_blocks: nil,
            instance_blocks: nil,
            person_blocks: nil,
            discussion_languages: nil
        )
    }

    private static func makePersonView(userName: String = "mark", isAdmin: Bool = false) -> PiefedPersonView {
        PiefedPersonView(
            activity_alert: nil,
            counts: PiefedPersonCounts(comment_count: 0, person_id: 10, post_count: 0),
            is_admin: isAdmin,
            person: makePerson(userName: userName)
        )
    }

    private static func makeCommunity(id: Int64 = 20, name: String = "technology") -> PiefedCommunity {
        PiefedCommunity(
            id: id,
            name: name,
            title: name,
            nsfw: false,
            ai_generated: false,
            question_answer: false,
            banned: false,
            restricted_to_mods: false,
            published: "2026-07-14T00:00:00.000000Z",
            updated: nil,
            deleted: false,
            removed: false,
            actor_id: "https://example.com/c/\(name)",
            local: true,
            hidden: false,
            instance_id: 1,
            ap_domain: "example.com",
            icon: nil,
            banner: nil,
            description: nil,
            posting_warning: nil
        )
    }

    private static func makePostCounts(postId: Int64) -> PiefedPostCounts {
        PiefedPostCounts(
            post_id: postId,
            comments: 0,
            score: 1,
            upvotes: 1,
            downvotes: 0,
            published: "2026-07-14T00:00:00.000000Z",
            newest_comment_time: "2026-07-14T00:00:00.000000Z",
            cross_posts: 0
        )
    }

    private static func makePostView(id: Int64, published: String) -> PiefedPostView {
        let post = PiefedPost(
            id: id,
            user_id: 10,
            community_id: 20,
            title: "Title \(id)",
            body: nil,
            url: nil,
            thumbnail_url: nil,
            small_thumbnail_url: nil,
            alt_text: nil,
            ap_id: "https://example.com/post/\(id)",
            local: true,
            nsfw: false,
            removed: false,
            deleted: false,
            locked: false,
            sticky: false,
            instance_sticky: false,
            language_id: 1,
            published: published,
            post_type: nil,
            ai_generated: nil,
            image_details: nil,
            tags: nil,
            flair: nil,
            cross_posts: nil
        )
        return PiefedPostView(
            post: post,
            creator: makePerson(),
            community: makeCommunity(),
            counts: makePostCounts(postId: id),
            subscribed: "NotSubscribed",
            saved: false,
            read: false,
            hidden: false,
            my_vote: 0,
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            banned_from_community: false,
            unread_comments: 0,
            creator_blocked: false,
            activity_alert: false,
            can_auth_user_moderate: false,
            flair_list: [],
            blurred: nil,
            filtered: nil
        )
    }

    private static func makeCommentCounts(commentId: Int64) -> PiefedCommentCounts {
        PiefedCommentCounts(
            comment_id: commentId,
            score: 1,
            upvotes: 1,
            downvotes: 0,
            published: "2026-07-14T00:00:00.000000Z",
            child_count: 0
        )
    }

    private static func makeCommentView(id: Int64, published: String) -> PiefedCommentView {
        let comment = PiefedComment(
            id: id,
            user_id: 10,
            post_id: 1,
            body: "Comment \(id)",
            deleted: false,
            answer: false,
            published: published,
            ap_id: "https://example.com/comment/\(id)",
            local: true,
            language_id: 1,
            distinguished: false,
            locked: false,
            removed: false,
            repliesEnabled: true,
            path: "0.\(id)"
        )
        return PiefedCommentView(
            comment: comment,
            creator: makePerson(),
            post: PiefedPost(
                id: 1,
                user_id: 10,
                community_id: 20,
                title: "Title",
                body: nil,
                url: nil,
                thumbnail_url: nil,
                small_thumbnail_url: nil,
                alt_text: nil,
                ap_id: "https://example.com/post/1",
                local: true,
                nsfw: false,
                removed: false,
                deleted: false,
                locked: false,
                sticky: false,
                instance_sticky: false,
                language_id: 1,
                published: "2026-01-01T00:00:00.000000Z",
                post_type: nil,
                ai_generated: nil,
                image_details: nil,
                tags: nil,
                flair: nil,
                cross_posts: nil
            ),
            community: makeCommunity(),
            counts: makeCommentCounts(commentId: id),
            banned_from_community: false,
            subscribed: "NotSubscribed",
            saved: false,
            creator_blocked: false,
            my_vote: 0,
            activity_alert: false,
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            can_auth_user_moderate: false
        )
    }
}
