//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import Testing
@testable import LemmyKit

/// Behavioral coverage for `Sources/LemmyKit/Adapters/*PiefedMapping.swift` -- the PieFed ->
/// neutral DTO adapters.
///
/// Renames and other fixture-observable mappings are asserted against the real Task-1 fixtures
/// (`Tests/LemmyKitTests/Fixtures/piefed-*.json`), decoded through the hand-written `Piefed*` wire
/// models (see `PiefedDecodingTests.swift`) and then run through the adapter under test -- not
/// tautological placeholders. Every captured fixture happens to carry `saved`/`read`/`hidden`/
/// `my_vote` all false/zero and `banned_from_community`/`hidden` (community visibility) with only
/// one branch represented, so the "true"/nonzero branches of the bare-bool-to-sentinel,
/// null-coalescing, and visibility-synthesis logic are covered with directly constructed `Piefed*`
/// values below instead -- still exercising the real adapter functions, just not routed through
/// JSON decoding for inputs the live capture never happened to produce.
struct PiefedMappingTests {
    private func fixture(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    private var decoder: JSONDecoder { JSONDecoder() }

    // MARK: - PostView / Post (fixture-backed renames)

    @Test
    func postViewMapsRenamedFields() throws {
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        let view = try #require(resp.posts.first)
        let neutral = neutralPostView(fromPiefed: view)

        // post.title -> post.name
        #expect(neutral.post.name == "'Man of Tomorrow': Xolo Maridueña to Return as Blue Beetle in James Gunn's Sequel")
        // post.user_id -> post.creatorId
        #expect(neutral.post.creatorId == 176_409)
        // creator.user_name -> creator.name
        #expect(neutral.creator.name == "TheImpressiveX")
        // community.restricted_to_mods -> community.postingRestrictedToMods
        #expect(neutral.community.postingRestrictedToMods == view.community.restricted_to_mods)
        #expect(neutral.community.postingRestrictedToMods == false)
        // subscribed "NotSubscribed" -> .notFollowing
        #expect(neutral.followState == .notFollowing)
        // my_vote 0 -> .none
        #expect(neutral.myVote == .none)
    }

    @Test
    func postMapsImageDimensionsAndAltTextFromEmbeddedFields() throws {
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        // The second post in the fixture carries alt_text + image_details (unlike the first,
        // which has neither) -- proves both decode-and-map when present, not just tolerate
        // absence. Unlike v3 (where these live on the enclosing PostView), PieFed carries them
        // directly on the post entity.
        let view = resp.posts[1]
        let neutral = neutralPostView(fromPiefed: view)

        #expect(neutral.post.altText == "Image from No Man's Sky: Featured Screenshot by Yummy")
        #expect(neutral.post.imageWidth == 1200)
        #expect(neutral.post.imageHeight == 675)
    }

    @Test
    func postFeaturedFieldsMapFromStickyFields() {
        let post = Self.makePost(sticky: true, instanceSticky: true)
        let neutral = neutralPost(fromPiefed: post, counts: Self.makePostCounts(postId: post.id))

        #expect(neutral.featuredCommunity == true)
        #expect(neutral.featuredLocal == true)
    }

    @Test
    func postHasNoUpdatedAtSource() {
        // PiefedPost carries no `updated`/`edited` timestamp of any kind -- always nil.
        let neutral = neutralPost(fromPiefed: Self.makePost(), counts: Self.makePostCounts())
        #expect(neutral.updatedAt == nil)
    }

    // MARK: - CommunityView / Community

    @Test
    func communityListPopulatesCounts() throws {
        let resp = try decoder.decode(PiefedListCommunitiesResponse.self, from: fixture("piefed-community_list"))
        let view = try #require(resp.communities.first)
        let neutral = neutralCommunityView(fromPiefed: view)

        #expect(neutral.community.name == "microblogs")
        #expect(neutral.community.subscribers == view.counts.total_subscriptions_count)
        #expect(neutral.community.posts == view.counts.post_count)
        #expect(neutral.community.comments == view.counts.post_reply_count)
        #expect(neutral.community.subscribers > 0)
    }

    @Test
    func bareCommunityEmbeddedInPostViewDefaultsCountsToZero() throws {
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        let view = try #require(resp.posts.first)
        let neutral = neutralCommunity(fromPiefed: view.community)

        #expect(neutral.subscribers == 0)
        #expect(neutral.posts == 0)
        #expect(neutral.comments == 0)
    }

    @Test
    func communityBannedFromCommunityNullCoalescesToFalse() throws {
        let resp = try decoder.decode(PiefedListCommunitiesResponse.self, from: fixture("piefed-community_list"))
        let view = try #require(resp.communities.first)
        #expect(view.banned_from_community == nil)

        let neutral = neutralCommunityView(fromPiefed: view)

        #expect(neutral.communityActions?.receivedBanAt == nil)
        #expect(neutral.isBlocked == false)
    }

    @Test
    func communityVisibilitySynthesizedFromHidden() {
        let visible = Self.makeCommunity(hidden: false)
        let hidden = Self.makeCommunity(hidden: true)

        #expect(neutralCommunity(fromPiefed: visible).visibility == ._public)
        #expect(neutralCommunity(fromPiefed: hidden).visibility == .unlisted)
    }

    @Test
    func communityUpdatedIsMappedOnEmbeddedShape() throws {
        // A Task-1 doc comment initially (wrongly) claimed `updated` is absent on the embedded
        // (post/comment) community shape; the model actually carries it -- verify it maps through.
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        let view = try #require(resp.posts.first)
        #expect(view.community.updated != nil)

        let neutral = neutralCommunity(fromPiefed: view.community)
        #expect(neutral.updatedAt != nil)
    }

    // MARK: - Comment / CommentView

    @Test
    func commentViewMapsRenamedFields() throws {
        let resp = try decoder.decode(PiefedGetCommentsResponse.self, from: fixture("piefed-comment_list"))
        let view = try #require(resp.comments.first)
        let neutral = neutralCommentView(fromPiefed: view)

        // comment.body -> comment.content
        #expect(neutral.comment.content == "Keep making live action movies nobody wants. Do it over and over again. ")
        // comment.user_id -> comment.creatorId
        #expect(neutral.comment.creatorId == 225_220)
        #expect(neutral.comment.path == "0.12115800")
        #expect(neutral.myVote == .none)
        #expect(neutral.followState == .notFollowing)
    }

    // MARK: - saved / read / vote sentinel derivation

    @Test
    func postViewSavedReadHiddenDeriveSentinelDates() {
        let view = Self.makePostView(saved: true, read: true, hidden: true, myVote: 1)
        let neutral = neutralPostView(fromPiefed: view)

        #expect(neutral.isSaved == true)
        #expect(neutral.isRead == true)
        #expect(neutral.isHidden == true)
        #expect(neutral.myVote == .up)
        #expect(neutral.postActions?.savedAt == v3ActionSentinel)
        #expect(neutral.postActions?.readAt == v3ActionSentinel)
        #expect(neutral.postActions?.hiddenAt == v3ActionSentinel)
    }

    @Test
    func postViewDownvoteMapsToDownDirection() {
        let view = Self.makePostView(myVote: -1)
        let neutral = neutralPostView(fromPiefed: view)

        #expect(neutral.myVote == .down)
    }

    @Test
    func commentViewSavedAndVoteDeriveSentinelDates() {
        let view = Self.makeCommentView(saved: true, myVote: -1)
        let neutral = neutralCommentView(fromPiefed: view)

        #expect(neutral.isSaved == true)
        #expect(neutral.myVote == .down)
        #expect(neutral.commentActions?.savedAt == v3ActionSentinel)
    }

    @Test
    func postViewBannedFromCommunityNilCoalescesToFalse() {
        let view = Self.makePostView(bannedFromCommunity: nil)
        let neutral = neutralPostView(fromPiefed: view)

        #expect(neutral.creatorBanned == false)
    }

    @Test
    func postViewBannedFromCommunityTrueMapsThrough() {
        let view = Self.makePostView(bannedFromCommunity: true)
        let neutral = neutralPostView(fromPiefed: view)

        #expect(neutral.creatorBanned == true)
    }

    // MARK: - subscribed follow-state fan-out

    @Test
    func followStateMapsAllThreeSubscribedValues() {
        #expect(neutralFollowState(fromPiefedSubscribed: "NotSubscribed") == .notFollowing)
        #expect(neutralFollowState(fromPiefedSubscribed: "Pending") == .pending)
        #expect(neutralFollowState(fromPiefedSubscribed: "Subscribed") == .accepted)
    }

    // MARK: - Person / PersonView

    @Test
    func personViewMapsBannedFromRealPersonField() throws {
        let resp = try decoder.decode(PiefedGetSiteResponse.self, from: fixture("piefed-site"))
        let admin = try #require(resp.admins.first)
        let neutral = neutralPersonView(fromPiefed: admin)

        #expect(neutral.person.name == "rimu")
        #expect(neutral.isAdmin == true)
        #expect(neutral.postCount == 912)
        #expect(neutral.isBanned == admin.person.banned)
        #expect(neutral.isBanned == false)
    }

    // MARK: - Site / SiteInfo

    @Test
    func siteInfoMapsAvailableFieldsAndDefaultsAbsentOnes() throws {
        let resp = try decoder.decode(PiefedGetSiteResponse.self, from: fixture("piefed-site"))
        let neutral = neutralSiteInfo(fromPiefed: resp)

        #expect(neutral.version == "1.7.5")
        #expect(neutral.site.name == "PieFed")
        #expect(neutral.site.users == resp.site.user_count)
        #expect(neutral.tagline == nil)
        #expect(neutral.admins.count == resp.admins.count)
        // No PieFed source for these -- documented defaults, not fixture data (see
        // `SiteInfoPiefedMapping.swift`).
        #expect(neutral.site.posts == 0)
        #expect(neutral.site.comments == 0)
        #expect(neutral.site.communities == 0)
        #expect(neutral.site.bannerUrl == nil)
    }

    // MARK: - Search

    @Test
    func searchResultsStructurallyMapsFixtureResponse() throws {
        let resp = try decoder.decode(PiefedSearchResponse.self, from: fixture("piefed-search"))
        let neutral = neutralSearchResults(fromPiefed: resp)

        #expect(neutral.communities.count == resp.communities.count)
        #expect(neutral.persons.count == resp.users.count)
        #expect(neutral.hasNextPage == false)
        #expect(neutral.hasPrevPage == false)
    }

    @Test
    func searchResultsMapsNonEmptyUsersArrayToPersons() {
        // The captured search fixture's `users` array happens to be empty (a Communities-type
        // search) -- construct a non-empty one directly to prove data, not just structure,
        // actually transfers through the `users` -> `persons` rename.
        let personView = Self.makePersonView(userName: "bob")
        let response = PiefedSearchResponse(posts: [], comments: [], communities: [], users: [personView], type_: "Users")

        let neutral = neutralSearchResults(fromPiefed: response)

        #expect(neutral.persons.count == 1)
        #expect(neutral.persons.first?.person.name == "bob")
    }

    // MARK: - ResolvedObject

    @Test
    func resolvedObjectPrefersPostOverOtherKinds() {
        let response = PiefedResolveObjectResponse(
            comment: Self.makeCommentView(),
            post: Self.makePostView(),
            community: nil,
            person: nil
        )

        let resolved = neutralResolvedObject(fromPiefed: response)

        #expect(resolved?.post != nil)
        #expect(resolved?.comment == nil)
    }

    @Test
    func resolvedObjectReturnsNilWhenAllAbsent() {
        let response = PiefedResolveObjectResponse(comment: nil, post: nil, community: nil, person: nil)
        #expect(neutralResolvedObject(fromPiefed: response) == nil)
    }

    // MARK: - Page / Cursor

    @Test
    func pageBuildsCursorFromNextPageString() throws {
        let resp = try decoder.decode(PiefedGetPostsResponse.self, from: fixture("piefed-post_list"))
        #expect(resp.next_page == "2")

        let page = neutralPage(fromPiefed: resp.posts, nextPage: resp.next_page) { neutralPostView(fromPiefed: $0) }

        #expect(page.items.count == resp.posts.count)
        #expect(page.nextPage == Cursor(rawValue: "2"))
        #expect(page.prevPage == nil)
    }

    @Test
    func pageNextPageNilWhenAbsent() {
        let page = neutralPage(fromPiefed: [Self.makePostView()], nextPage: nil) { neutralPostView(fromPiefed: $0) }
        #expect(page.nextPage == nil)
    }

    // MARK: - piefedDate

    @Test
    func piefedDateParsesFractionalSecondsWithTrailingZ() {
        #expect(piefedDate("2026-07-14T22:48:42.055960Z") != nil)
    }

    @Test
    func piefedDateParsesFractionalSecondsWithoutTrailingZ() {
        #expect(piefedDate("2026-07-14T22:48:42.055960") != nil)
    }

    @Test
    func piefedDateNilForNilInput() {
        #expect(piefedDate(nil) == nil)
    }

    // MARK: - Factories

    //
    // `Piefed*` models declare no default field values, so every synthetic instance must specify
    // every property; these factories centralize sensible defaults for whichever fields a given
    // test doesn't care about, matching the pattern `PostViewMappingTests.swift` uses for v3/v4.

    private static func makePost(
        id: Int64 = 1,
        userId: Int64 = 10,
        communityId: Int64 = 20,
        title: String = "Title",
        body: String? = nil,
        sticky: Bool = false,
        instanceSticky: Bool = false,
        altText: String? = nil,
        imageDetails: PiefedImageDetails? = nil
    ) -> PiefedPost {
        PiefedPost(
            id: id,
            user_id: userId,
            community_id: communityId,
            title: title,
            body: body,
            url: nil,
            thumbnail_url: nil,
            small_thumbnail_url: nil,
            alt_text: altText,
            ap_id: "https://example.com/post/\(id)",
            local: true,
            nsfw: false,
            removed: false,
            deleted: false,
            locked: false,
            sticky: sticky,
            instance_sticky: instanceSticky,
            language_id: 1,
            published: "2026-07-14T00:00:00.000000Z",
            post_type: nil,
            ai_generated: nil,
            image_details: imageDetails,
            tags: nil,
            flair: nil,
            cross_posts: nil
        )
    }

    private static func makePostCounts(
        postId: Int64 = 1,
        comments: Int64 = 5,
        score: Int64 = 1,
        upvotes: Int64 = 1,
        downvotes: Int64 = 0
    ) -> PiefedPostCounts {
        PiefedPostCounts(
            post_id: postId,
            comments: comments,
            score: score,
            upvotes: upvotes,
            downvotes: downvotes,
            published: "2026-07-14T00:00:00.000000Z",
            newest_comment_time: "2026-07-14T00:00:00.000000Z",
            cross_posts: 0
        )
    }

    private static func makePerson(
        id: Int64 = 10,
        userName: String = "alice",
        banned: Bool = false
    ) -> PiefedPerson {
        PiefedPerson(
            id: id,
            user_name: userName,
            title: userName,
            banned: banned,
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

    private static func makeCommunity(
        id: Int64 = 20,
        name: String = "technology",
        restrictedToMods: Bool = false,
        hidden: Bool = false,
        updated: String? = "2026-07-14T00:00:00.000000Z"
    ) -> PiefedCommunity {
        PiefedCommunity(
            id: id,
            name: name,
            title: name,
            nsfw: false,
            ai_generated: false,
            question_answer: false,
            banned: false,
            restricted_to_mods: restrictedToMods,
            published: "2026-07-14T00:00:00.000000Z",
            updated: updated,
            deleted: false,
            removed: false,
            actor_id: "https://example.com/c/\(name)",
            local: true,
            hidden: hidden,
            instance_id: 1,
            ap_domain: "example.com",
            icon: nil,
            banner: nil,
            description: nil,
            posting_warning: nil
        )
    }

    private static func makeComment(
        id: Int64 = 100,
        userId: Int64 = 10,
        postId: Int64 = 1,
        body: String = "Hello"
    ) -> PiefedComment {
        PiefedComment(
            id: id,
            user_id: userId,
            post_id: postId,
            body: body,
            deleted: false,
            answer: false,
            published: "2026-07-14T00:00:00.000000Z",
            ap_id: "https://example.com/comment/\(id)",
            local: true,
            language_id: 1,
            distinguished: false,
            locked: false,
            removed: false,
            repliesEnabled: true,
            path: "0.\(id)"
        )
    }

    private static func makeCommentCounts(commentId: Int64 = 100) -> PiefedCommentCounts {
        PiefedCommentCounts(
            comment_id: commentId,
            score: 1,
            upvotes: 1,
            downvotes: 0,
            published: "2026-07-14T00:00:00.000000Z",
            child_count: 0
        )
    }

    private static func makePostView(
        saved: Bool = false,
        read: Bool = false,
        hidden: Bool = false,
        myVote: Int = 0,
        bannedFromCommunity: Bool? = false,
        subscribed: String = "NotSubscribed",
        creatorBlocked: Bool? = false
    ) -> PiefedPostView {
        let post = makePost()
        return PiefedPostView(
            post: post,
            creator: makePerson(),
            community: makeCommunity(),
            counts: makePostCounts(postId: post.id),
            subscribed: subscribed,
            saved: saved,
            read: read,
            hidden: hidden,
            my_vote: myVote,
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            banned_from_community: bannedFromCommunity,
            unread_comments: 0,
            creator_blocked: creatorBlocked,
            activity_alert: false,
            can_auth_user_moderate: false,
            flair_list: [],
            blurred: nil,
            filtered: nil
        )
    }

    private static func makeCommentView(
        saved: Bool = false,
        myVote: Int = 0,
        bannedFromCommunity: Bool = false,
        subscribed: String = "NotSubscribed",
        creatorBlocked: Bool? = false
    ) -> PiefedCommentView {
        PiefedCommentView(
            comment: makeComment(),
            creator: makePerson(),
            post: makePost(),
            community: makeCommunity(),
            counts: makeCommentCounts(),
            banned_from_community: bannedFromCommunity,
            subscribed: subscribed,
            saved: saved,
            creator_blocked: creatorBlocked,
            my_vote: myVote,
            activity_alert: false,
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            can_auth_user_moderate: false
        )
    }

    private static func makePersonView(
        userName: String = "alice",
        isAdmin: Bool = false
    ) -> PiefedPersonView {
        PiefedPersonView(
            activity_alert: false,
            counts: PiefedPersonCounts(comment_count: 0, person_id: 1, post_count: 0),
            is_admin: isAdmin,
            person: makePerson(userName: userName)
        )
    }
}
