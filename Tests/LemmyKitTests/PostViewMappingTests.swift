//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import XCTest
@testable import LemmyKit

/// Behavioral coverage for the `Sources/LemmyKit/Adapters/PostViewV3Mapping.swift` /
/// `PostViewV4Mapping.swift` mapping functions.
///
/// The point of these adapters is that a v3-backed and a v4-backed `PostView` read identically
/// to a call site, even though the two wire shapes are quite different (v3: booleans + a signed
/// vote score, no per-viewer timestamps; v4: per-viewer timestamps directly). `test
/// V3AndV4BackendsProduceIdenticalNeutralPostView` below constructs equivalent per-viewer state
/// on both generated shapes and asserts the derived neutral values come out identically -- that
/// cross-backend agreement, not just each mapping in isolation, is what this file exists to
/// prove.
final class PostViewMappingTests: XCTestCase {
    // MARK: - v3 fixtures

    private static let v3PublishedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private static func makeV3PostAggregates(
        comments: Int64 = 10,
        score: Int64 = 12,
        upvotes: Int64 = 14,
        downvotes: Int64 = 2
    ) -> LemmyKit.Components.Schemas.PostAggregates {
        LemmyKit.Components.Schemas.PostAggregates(
            post_id: 42,
            comments: comments,
            score: score,
            upvotes: upvotes,
            downvotes: downvotes,
            published: v3PublishedDate,
            newest_comment_time: v3PublishedDate
        )
    }

    private static func makeV3Post() -> LemmyKit.Components.Schemas.Post {
        LemmyKit.Components.Schemas.Post(
            id: 42,
            name: "Hello",
            creator_id: 1,
            community_id: 2,
            removed: false,
            locked: false,
            published: v3PublishedDate,
            deleted: false,
            nsfw: false,
            ap_id: "https://example.com/post/42",
            local: true,
            language_id: 0,
            featured_community: false,
            featured_local: false
        )
    }

    private static func makeV3Person() -> LemmyKit.Components.Schemas.Person {
        LemmyKit.Components.Schemas.Person(
            id: 1,
            name: "alice",
            banned: false,
            published: v3PublishedDate,
            actor_id: "https://example.com/u/alice",
            local: true,
            deleted: false,
            bot_account: false,
            instance_id: 1
        )
    }

    private static func makeV3Community() -> LemmyKit.Components.Schemas.Community {
        LemmyKit.Components.Schemas.Community(
            id: 2,
            name: "technology",
            title: "Technology",
            removed: false,
            published: v3PublishedDate,
            deleted: false,
            nsfw: false,
            actor_id: "https://example.com/c/technology",
            local: true,
            hidden: false,
            posting_restricted_to_mods: false,
            instance_id: 1,
            visibility: .Public
        )
    }

    private static func makeV3PostView(
        saved: Bool = false,
        read: Bool = false,
        hidden: Bool = false,
        creatorBlocked: Bool = false,
        myVote: Int32? = nil,
        unreadComments: Int64 = 0,
        subscribed: LemmyKit.Components.Schemas.SubscribedType = .NotSubscribed,
        counts: LemmyKit.Components.Schemas.PostAggregates? = nil,
        imageDetails: LemmyKit.Components.Schemas.ImageDetails? = nil
    ) -> LemmyKit.Components.Schemas.PostView {
        LemmyKit.Components.Schemas.PostView(
            post: makeV3Post(),
            creator: makeV3Person(),
            community: makeV3Community(),
            image_details: imageDetails,
            creator_banned_from_community: false,
            banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            counts: counts ?? makeV3PostAggregates(),
            subscribed: subscribed,
            saved: saved,
            read: read,
            hidden: hidden,
            creator_blocked: creatorBlocked,
            my_vote: myVote,
            unread_comments: unreadComments
        )
    }

    // MARK: - v4 fixtures

    private static let v4Timestamp = "2024-06-09T11:54:37.981990Z"

    private static func makeV4Post(
        comments: Int64 = 10,
        score: Int64 = 12,
        upvotes: Int64 = 14,
        downvotes: Int64 = 2
    ) -> LemmyKitV4Generated.Components.Schemas.Post {
        LemmyKitV4Generated.Components.Schemas.Post(
            federation_pending: false,
            unresolved_report_count: 0,
            report_count: 0,
            downvotes: downvotes,
            upvotes: upvotes,
            score: score,
            comments: comments,
            featured_local: false,
            featured_community: false,
            language_id: 0,
            local: true,
            ap_id: "https://example.com/post/42",
            nsfw: false,
            deleted: false,
            published_at: v4Timestamp,
            locked: false,
            removed: false,
            community_id: 2,
            creator_id: 1,
            name: "Hello",
            id: 42
        )
    }

    private static func makeV4Person() -> LemmyKitV4Generated.Components.Schemas.Person {
        LemmyKitV4Generated.Components.Schemas.Person(
            comment_count: 0,
            post_count: 0,
            instance_id: 1,
            bot_account: false,
            deleted: false,
            last_refreshed_at: v4Timestamp,
            local: true,
            ap_id: "https://example.com/u/alice",
            published_at: v4Timestamp,
            name: "alice",
            id: 1
        )
    }

    private static func makeV4Community() -> LemmyKitV4Generated.Components.Schemas.Community {
        LemmyKitV4Generated.Components.Schemas.Community(
            local_removed: false,
            unresolved_report_count: 0,
            report_count: 0,
            subscribers_local: 0,
            users_active_half_year: 0,
            users_active_month: 0,
            users_active_week: 0,
            users_active_day: 0,
            comments: 200,
            posts: 50,
            subscribers: 100,
            visibility: ._public,
            instance_id: 1,
            posting_restricted_to_mods: false,
            last_refreshed_at: v4Timestamp,
            local: true,
            ap_id: "https://example.com/c/technology",
            nsfw: false,
            deleted: false,
            published_at: v4Timestamp,
            removed: false,
            name: "technology",
            id: 2
        )
    }

    private static func makeV4PostView(
        post: LemmyKitV4Generated.Components.Schemas.Post? = nil,
        postActions: LemmyKitV4Generated.Components.Schemas.PostActions? = nil,
        communityActions: LemmyKitV4Generated.Components.Schemas.CommunityActions? = nil,
        personActions: LemmyKitV4Generated.Components.Schemas.PersonActions? = nil,
        imageDetails: LemmyKitV4Generated.Components.Schemas.ImageDetails? = nil
    ) -> LemmyKitV4Generated.Components.Schemas.PostView {
        LemmyKitV4Generated.Components.Schemas.PostView(
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_banned: false,
            can_mod: false,
            tags: [],
            creator_is_admin: false,
            post_actions: postActions,
            person_actions: personActions,
            community_actions: communityActions,
            image_details: imageDetails,
            community: makeV4Community(),
            creator: makeV4Person(),
            post: post ?? makeV4Post()
        )
    }

    // MARK: - v4 -> neutral

    func testNeutralPostViewFromV4MapsPerViewerState() {
        let v4View = Self.makeV4PostView(
            postActions: .init(
                vote_is_upvote: false,
                read_comments_amount: 3,
                voted_at: Self.v4Timestamp,
                saved_at: Self.v4Timestamp
            ),
            communityActions: .init(follow_state: .accepted),
            personActions: .init(blocked_at: Self.v4Timestamp)
        )

        let neutral = neutralPostView(fromV4: v4View)

        XCTAssertTrue(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .down)
        XCTAssertEqual(neutral.unreadCommentCount, 7)
        XCTAssertEqual(neutral.followState, .accepted)
        XCTAssertTrue(neutral.isCreatorBlocked)

        // The flattened vote/comment counts survive the mapping unchanged.
        XCTAssertEqual(neutral.post.score, 12)
        XCTAssertEqual(neutral.post.upvotes, 14)
        XCTAssertEqual(neutral.post.downvotes, 2)
        XCTAssertEqual(neutral.post.comments, 10)
    }

    func testNeutralPostViewFromV4AbsentActionsDefaultToSignedOutShape() {
        // No post_actions/community_actions/person_actions at all -- the shape of a signed-out
        // viewer, or a post the account has never interacted with.
        let v4View = Self.makeV4PostView()

        let neutral = neutralPostView(fromV4: v4View)

        XCTAssertNil(neutral.postActions)
        XCTAssertFalse(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .none)
        XCTAssertEqual(neutral.followState, .notFollowing)
        XCTAssertFalse(neutral.isCreatorBlocked)
    }

    // MARK: - v3 -> neutral

    func testNeutralPostViewFromV3MapsPerViewerState() {
        // v3's `unread_comments` is literally "how many are unread" -- the inverse of v4's
        // `read_comments_amount` ("how many were read"). 10 comments, 3 read (matching the v4
        // test above) means 7 unread, so `unreadComments` here is 7, not 3.
        let v3View = Self.makeV3PostView(
            saved: true,
            creatorBlocked: true,
            myVote: -1,
            unreadComments: 7,
            subscribed: .Subscribed
        )

        let neutral = neutralPostView(fromV3: v3View)

        XCTAssertTrue(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .down)
        XCTAssertEqual(neutral.unreadCommentCount, 7)
        XCTAssertEqual(neutral.followState, .accepted)
        XCTAssertTrue(neutral.isCreatorBlocked)

        XCTAssertEqual(neutral.post.score, 12)
        XCTAssertEqual(neutral.post.upvotes, 14)
        XCTAssertEqual(neutral.post.downvotes, 2)
        XCTAssertEqual(neutral.post.comments, 10)
    }

    func testNeutralPostViewFromV3NoVoteYieldsNoneVote() {
        XCTAssertEqual(neutralPostView(fromV3: Self.makeV3PostView(myVote: nil)).myVote, .none)
        XCTAssertEqual(neutralPostView(fromV3: Self.makeV3PostView(myVote: 0)).myVote, .none)
    }

    // MARK: - image dimensions

    /// v3 carries image pixel dimensions on `PostView.image_details`; the mapping threads them
    /// onto the neutral `Post`.
    func testNeutralPostViewFromV3MapsImageDimensions() {
        let v3View = Self.makeV3PostView(imageDetails: .init(
            link: "https://example.com/img.jpg",
            width: 1280,
            height: 720,
            content_type: "image/jpeg"
        ))

        let neutral = neutralPostView(fromV3: v3View)

        XCTAssertEqual(neutral.post.imageWidth, 1280)
        XCTAssertEqual(neutral.post.imageHeight, 720)
    }

    /// No `image_details` (a text post, or an unresolved link) leaves the neutral dimensions nil.
    func testNeutralPostViewFromV3WithoutImageDetailsYieldsNilDimensions() {
        let neutral = neutralPostView(fromV3: Self.makeV3PostView())

        XCTAssertNil(neutral.post.imageWidth)
        XCTAssertNil(neutral.post.imageHeight)
    }

    /// v4 also carries image pixel dimensions on `PostView.image_details`; the mapping threads
    /// them onto the neutral `Post` identically to v3.
    func testNeutralPostViewFromV4MapsImageDimensions() {
        let v4View = Self.makeV4PostView(imageDetails: .init(
            content_type: "image/jpeg",
            height: 720,
            width: 1280,
            link: "https://example.com/img.jpg"
        ))

        let neutral = neutralPostView(fromV4: v4View)

        XCTAssertEqual(neutral.post.imageWidth, 1280)
        XCTAssertEqual(neutral.post.imageHeight, 720)
    }

    /// A v3-backed and a v4-backed `Post` given equivalent image dimensions read identically.
    func testV3AndV4BackendsProduceIdenticalImageDimensions() {
        let fromV3 = neutralPostView(fromV3: Self.makeV3PostView(imageDetails: .init(
            link: "https://example.com/img.jpg",
            width: 1280,
            height: 720,
            content_type: "image/jpeg"
        )))
        let fromV4 = neutralPostView(fromV4: Self.makeV4PostView(imageDetails: .init(
            content_type: "image/jpeg",
            height: 720,
            width: 1280,
            link: "https://example.com/img.jpg"
        )))

        XCTAssertEqual(fromV3.post.imageWidth, fromV4.post.imageWidth)
        XCTAssertEqual(fromV3.post.imageHeight, fromV4.post.imageHeight)
    }

    // MARK: - both backends agree

    /// The whole point of the neutral surface: a v3-backed and a v4-backed `PostView`, given
    /// equivalent per-viewer state, must expose the *same* derived values at the call site --
    /// callers should never need to know or care which backend produced the view.
    func testV3AndV4BackendsProduceIdenticalNeutralPostView() {
        // 10 comments, 3 read / 7 unread on both sides -- see the polarity note in
        // `testNeutralPostViewFromV3MapsPerViewerState` above for why v3's `unreadComments`
        // is 7 while v4's `read_comments_amount` below is 3.
        let fromV3 = neutralPostView(fromV3: Self.makeV3PostView(
            saved: true,
            creatorBlocked: true,
            myVote: -1,
            unreadComments: 7,
            subscribed: .Subscribed
        ))

        let fromV4 = neutralPostView(fromV4: Self.makeV4PostView(
            postActions: .init(
                vote_is_upvote: false,
                read_comments_amount: 3,
                voted_at: Self.v4Timestamp,
                saved_at: Self.v4Timestamp
            ),
            communityActions: .init(follow_state: .accepted),
            personActions: .init(blocked_at: Self.v4Timestamp)
        ))

        XCTAssertEqual(fromV3.isSaved, fromV4.isSaved)
        XCTAssertEqual(fromV3.myVote, fromV4.myVote)
        XCTAssertEqual(fromV3.unreadCommentCount, fromV4.unreadCommentCount)
        XCTAssertEqual(fromV3.followState, fromV4.followState)
        XCTAssertEqual(fromV3.isCreatorBlocked, fromV4.isCreatorBlocked)
        XCTAssertEqual(fromV3.post.score, fromV4.post.score)
        XCTAssertEqual(fromV3.post.upvotes, fromV4.post.upvotes)
        XCTAssertEqual(fromV3.post.downvotes, fromV4.post.downvotes)
        XCTAssertEqual(fromV3.post.comments, fromV4.post.comments)
    }
}
