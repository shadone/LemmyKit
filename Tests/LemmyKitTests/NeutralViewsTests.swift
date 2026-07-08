//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import XCTest
@testable import LemmyKit

/// Behavioral coverage for the version-neutral composite view types in
/// `Sources/LemmyKit/Neutral/`: `PostView` and `CommentView`. These compose the neutral entities
/// with optional per-viewer action structs; the fields themselves are plain storage, so this
/// file covers only the derived properties, which are what call sites actually depend on.
final class NeutralViewsTests: XCTestCase {
    // MARK: - Fixtures

    private static let now = Date()

    private static func makePost(comments: Int64 = 10) -> Post {
        Post(
            id: 42,
            name: "Hello",
            creatorId: 1,
            communityId: 2,
            apId: "https://example.com/post/42",
            local: true,
            nsfw: false,
            removed: false,
            deleted: false,
            locked: false,
            featuredCommunity: false,
            featuredLocal: false,
            languageId: 0,
            publishedAt: now,
            score: 10,
            upvotes: 12,
            downvotes: 2,
            comments: comments
        )
    }

    private static func makeComment() -> Comment {
        Comment(
            id: 7,
            postId: 42,
            creatorId: 1,
            content: "Nice post",
            path: "0.7",
            removed: false,
            deleted: false,
            distinguished: false,
            languageId: 0,
            publishedAt: now,
            apId: "https://example.com/comment/7",
            local: true,
            score: 4,
            upvotes: 5,
            downvotes: 1,
            childCount: 0
        )
    }

    private static func makeCreator() -> Person {
        Person(
            id: 1,
            name: "alice",
            apId: "https://example.com/u/alice",
            botAccount: false,
            deleted: false,
            local: true,
            publishedAt: now,
            postCount: 5,
            commentCount: 10
        )
    }

    private static func makeCommunity() -> Community {
        Community(
            id: 2,
            name: "technology",
            apId: "https://example.com/c/technology",
            visibility: ._public,
            local: true,
            nsfw: false,
            postingRestrictedToMods: false,
            removed: false,
            deleted: false,
            publishedAt: now,
            subscribers: 100,
            posts: 50,
            comments: 200
        )
    }

    // MARK: - PostView

    func testPostViewDerivedPropertiesReflectComposedActions() {
        let view = PostView(
            post: Self.makePost(),
            creator: Self.makeCreator(),
            community: Self.makeCommunity(),
            postActions: PostActions(
                readAt: Self.now,
                hiddenAt: Self.now,
                savedAt: Self.now,
                votedAt: Self.now,
                voteIsUpvote: true
            ),
            communityActions: CommunityActions(followState: .accepted),
            personActions: PersonActions(blockedAt: Self.now)
        )

        XCTAssertTrue(view.isSaved)
        XCTAssertTrue(view.isRead)
        XCTAssertTrue(view.isHidden)
        XCTAssertEqual(view.myVote, .up)
        XCTAssertEqual(view.followState, .accepted)
        XCTAssertTrue(view.isCreatorBlocked)
    }

    func testPostViewDerivedPropertiesDefaultWhenActionsAreNil() {
        let view = PostView(
            post: Self.makePost(),
            creator: Self.makeCreator(),
            community: Self.makeCommunity()
        )

        XCTAssertFalse(view.isSaved)
        XCTAssertFalse(view.isRead)
        XCTAssertFalse(view.isHidden)
        XCTAssertEqual(view.myVote, .none)
        XCTAssertEqual(view.followState, .notFollowing)
        XCTAssertFalse(view.isCreatorBlocked)
    }

    func testPostViewUnreadCommentCountSubtractsReadAmount() {
        let view = PostView(
            post: Self.makePost(comments: 10),
            creator: Self.makeCreator(),
            community: Self.makeCommunity(),
            postActions: PostActions(readCommentsAmount: 3)
        )

        XCTAssertEqual(view.unreadCommentCount, 7)
    }

    func testPostViewUnreadCommentCountFallsBackToTotalWhenReadAmountIsNil() {
        let view = PostView(
            post: Self.makePost(comments: 10),
            creator: Self.makeCreator(),
            community: Self.makeCommunity(),
            postActions: PostActions(readCommentsAmount: nil)
        )

        XCTAssertEqual(view.unreadCommentCount, 10)
    }

    func testPostViewUnreadCommentCountFlooredAtZero() {
        let view = PostView(
            post: Self.makePost(comments: 10),
            creator: Self.makeCreator(),
            community: Self.makeCommunity(),
            postActions: PostActions(readCommentsAmount: 99)
        )

        XCTAssertEqual(view.unreadCommentCount, 0)
    }

    func testPostViewUnreadCommentCountWhenPostActionsIsNil() {
        let view = PostView(
            post: Self.makePost(comments: 10),
            creator: Self.makeCreator(),
            community: Self.makeCommunity()
        )

        XCTAssertEqual(view.unreadCommentCount, 10)
    }

    // MARK: - CommentView

    func testCommentViewDerivedPropertiesReflectComposedActions() {
        let view = CommentView(
            comment: Self.makeComment(),
            creator: Self.makeCreator(),
            post: Self.makePost(),
            community: Self.makeCommunity(),
            commentActions: CommentActions(savedAt: Self.now, votedAt: Self.now, voteIsUpvote: false),
            communityActions: CommunityActions(followState: .pending),
            personActions: PersonActions(blockedAt: Self.now)
        )

        XCTAssertTrue(view.isSaved)
        XCTAssertEqual(view.myVote, .down)
        XCTAssertEqual(view.followState, .pending)
        XCTAssertTrue(view.isCreatorBlocked)
    }

    func testCommentViewDerivedPropertiesDefaultWhenActionsAreNil() {
        let view = CommentView(
            comment: Self.makeComment(),
            creator: Self.makeCreator(),
            post: Self.makePost(),
            community: Self.makeCommunity()
        )

        XCTAssertFalse(view.isSaved)
        XCTAssertEqual(view.myVote, .none)
        XCTAssertEqual(view.followState, .notFollowing)
        XCTAssertFalse(view.isCreatorBlocked)
    }
}
