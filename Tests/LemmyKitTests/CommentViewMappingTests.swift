//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import XCTest
@testable import LemmyKit

/// Behavioral coverage for the `Sources/LemmyKit/Adapters/CommentViewV3Mapping.swift` /
/// `CommentViewV4Mapping.swift` mapping functions.
///
/// Mirrors `PostViewMappingTests`: the point of these adapters is that a v3-backed and a
/// v4-backed `CommentView` read identically to a call site, even though the two wire shapes are
/// quite different (v3: booleans + a signed vote score, no per-viewer timestamps; v4: per-viewer
/// timestamps directly). `testV3AndV4BackendsProduceIdenticalNeutralCommentView` below constructs
/// equivalent per-viewer state on both generated shapes and asserts the derived neutral values
/// come out identically -- that cross-backend agreement, not just each mapping in isolation, is
/// what this file exists to prove.
final class CommentViewMappingTests: XCTestCase {
    // MARK: - v3 fixtures

    private static let v3PublishedDate = Date(timeIntervalSince1970: 1_700_000_000)

    private static func makeV3CommentAggregates(
        score: Int64 = 12,
        upvotes: Int64 = 14,
        downvotes: Int64 = 2,
        childCount: Int32 = 3
    ) -> LemmyKit.Components.Schemas.CommentAggregates {
        LemmyKit.Components.Schemas.CommentAggregates(
            comment_id: 99,
            score: score,
            upvotes: upvotes,
            downvotes: downvotes,
            published: v3PublishedDate,
            child_count: childCount
        )
    }

    private static func makeV3Comment() -> LemmyKit.Components.Schemas.Comment {
        LemmyKit.Components.Schemas.Comment(
            id: 99,
            creator_id: 1,
            post_id: 42,
            content: "Hello, world",
            removed: false,
            published: v3PublishedDate,
            deleted: false,
            ap_id: "https://example.com/comment/99",
            local: true,
            path: "0.99",
            distinguished: false,
            language_id: 0
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

    private static func makeV3CommentView(
        saved: Bool = false,
        creatorBlocked: Bool = false,
        myVote: Int32? = nil,
        subscribed: LemmyKit.Components.Schemas.SubscribedType = .NotSubscribed,
        counts: LemmyKit.Components.Schemas.CommentAggregates? = nil
    ) -> LemmyKit.Components.Schemas.CommentView {
        LemmyKit.Components.Schemas.CommentView(
            comment: makeV3Comment(),
            creator: makeV3Person(),
            post: makeV3Post(),
            community: makeV3Community(),
            counts: counts ?? makeV3CommentAggregates(),
            creator_banned_from_community: false,
            banned_from_community: false,
            creator_is_moderator: false,
            creator_is_admin: false,
            subscribed: subscribed,
            saved: saved,
            creator_blocked: creatorBlocked,
            my_vote: myVote
        )
    }

    // MARK: - v4 fixtures

    private static let v4Timestamp = "2024-06-09T11:54:37.981990Z"

    private static func makeV4Comment(
        score: Int64 = 12,
        upvotes: Int64 = 14,
        downvotes: Int64 = 2,
        childCount: Int64 = 3
    ) -> LemmyKitV4Generated.Components.Schemas.Comment {
        LemmyKitV4Generated.Components.Schemas.Comment(
            locked: false,
            federation_pending: false,
            unresolved_report_count: 0,
            report_count: 0,
            child_count: childCount,
            downvotes: downvotes,
            upvotes: upvotes,
            score: score,
            language_id: 0,
            distinguished: false,
            path: "0.99",
            local: true,
            ap_id: "https://example.com/comment/99",
            deleted: false,
            published_at: v4Timestamp,
            removed: false,
            content: "Hello, world",
            post_id: 42,
            creator_id: 1,
            id: 99
        )
    }

    private static func makeV4Post() -> LemmyKitV4Generated.Components.Schemas.Post {
        LemmyKitV4Generated.Components.Schemas.Post(
            federation_pending: false,
            unresolved_report_count: 0,
            report_count: 0,
            downvotes: 2,
            upvotes: 14,
            score: 12,
            comments: 10,
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

    private static func makeV4CommentView(
        comment: LemmyKitV4Generated.Components.Schemas.Comment? = nil,
        commentActions: LemmyKitV4Generated.Components.Schemas.CommentActions? = nil,
        communityActions: LemmyKitV4Generated.Components.Schemas.CommunityActions? = nil,
        personActions: LemmyKitV4Generated.Components.Schemas.PersonActions? = nil
    ) -> LemmyKitV4Generated.Components.Schemas.CommentView {
        LemmyKitV4Generated.Components.Schemas.CommentView(
            creator_banned_from_community: false,
            creator_is_moderator: false,
            creator_banned: false,
            can_mod: false,
            tags: [],
            creator_is_admin: false,
            person_actions: personActions,
            comment_actions: commentActions,
            community_actions: communityActions,
            community: makeV4Community(),
            post: makeV4Post(),
            creator: makeV4Person(),
            comment: comment ?? makeV4Comment()
        )
    }

    // MARK: - v4 -> neutral

    func testNeutralCommentViewFromV4MapsPerViewerState() {
        let v4View = Self.makeV4CommentView(
            commentActions: .init(
                vote_is_upvote: true,
                saved_at: Self.v4Timestamp,
                voted_at: Self.v4Timestamp
            ),
            communityActions: .init(follow_state: .accepted),
            personActions: .init(blocked_at: Self.v4Timestamp)
        )

        let neutral = neutralCommentView(fromV4: v4View)

        XCTAssertTrue(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .up)
        XCTAssertEqual(neutral.followState, .accepted)
        XCTAssertTrue(neutral.isCreatorBlocked)

        // The flattened vote/child counts survive the mapping unchanged.
        XCTAssertEqual(neutral.comment.score, 12)
        XCTAssertEqual(neutral.comment.upvotes, 14)
        XCTAssertEqual(neutral.comment.downvotes, 2)
        XCTAssertEqual(neutral.comment.childCount, 3)
    }

    func testNeutralCommentViewFromV4AbsentActionsDefaultToSignedOutShape() {
        // No comment_actions/community_actions/person_actions at all -- the shape of a
        // signed-out viewer, or a comment the account has never interacted with.
        let v4View = Self.makeV4CommentView()

        let neutral = neutralCommentView(fromV4: v4View)

        XCTAssertNil(neutral.commentActions)
        XCTAssertFalse(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .none)
        XCTAssertEqual(neutral.followState, .notFollowing)
        XCTAssertFalse(neutral.isCreatorBlocked)
    }

    // MARK: - v3 -> neutral

    func testNeutralCommentViewFromV3MapsPerViewerState() {
        let v3View = Self.makeV3CommentView(
            saved: true,
            creatorBlocked: true,
            myVote: 1,
            subscribed: .Subscribed
        )

        let neutral = neutralCommentView(fromV3: v3View)

        XCTAssertTrue(neutral.isSaved)
        XCTAssertEqual(neutral.myVote, .up)
        XCTAssertEqual(neutral.followState, .accepted)
        XCTAssertTrue(neutral.isCreatorBlocked)

        XCTAssertEqual(neutral.comment.score, 12)
        XCTAssertEqual(neutral.comment.upvotes, 14)
        XCTAssertEqual(neutral.comment.downvotes, 2)
        XCTAssertEqual(neutral.comment.childCount, 3)
    }

    func testNeutralCommentViewFromV3NoVoteYieldsNoneVote() {
        XCTAssertEqual(neutralCommentView(fromV3: Self.makeV3CommentView(myVote: nil)).myVote, .none)
        XCTAssertEqual(neutralCommentView(fromV3: Self.makeV3CommentView(myVote: 0)).myVote, .none)
    }

    // MARK: - both backends agree

    /// The whole point of the neutral surface: a v3-backed and a v4-backed `CommentView`, given
    /// equivalent per-viewer state, must expose the *same* derived values at the call site --
    /// callers should never need to know or care which backend produced the view.
    func testV3AndV4BackendsProduceIdenticalNeutralCommentView() {
        let fromV3 = neutralCommentView(fromV3: Self.makeV3CommentView(
            saved: true,
            creatorBlocked: true,
            myVote: 1,
            subscribed: .Subscribed
        ))

        let fromV4 = neutralCommentView(fromV4: Self.makeV4CommentView(
            commentActions: .init(
                vote_is_upvote: true,
                saved_at: Self.v4Timestamp,
                voted_at: Self.v4Timestamp
            ),
            communityActions: .init(follow_state: .accepted),
            personActions: .init(blocked_at: Self.v4Timestamp)
        ))

        XCTAssertEqual(fromV3.isSaved, fromV4.isSaved)
        XCTAssertEqual(fromV3.myVote, fromV4.myVote)
        XCTAssertEqual(fromV3.followState, fromV4.followState)
        XCTAssertEqual(fromV3.isCreatorBlocked, fromV4.isCreatorBlocked)
        XCTAssertEqual(fromV3.comment.score, fromV4.comment.score)
        XCTAssertEqual(fromV3.comment.upvotes, fromV4.comment.upvotes)
        XCTAssertEqual(fromV3.comment.downvotes, fromV4.comment.downvotes)
        XCTAssertEqual(fromV3.comment.childCount, fromV4.comment.childCount)
    }
}
