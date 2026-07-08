//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

/// Behavioral coverage for the version-neutral per-viewer action structs in
/// `Sources/LemmyKit/Neutral/`: `PostActions`, `CommentActions`, `CommunityActions`, and
/// `PersonActions`. Each struct's stored fields are plain optionals with no logic; this file
/// covers only the derived properties, which are the actual behavior call sites depend on.
final class NeutralActionsTests: XCTestCase {
    // MARK: - PostActions

    func testPostActionsIsReadReflectsReadAt() {
        XCTAssertTrue(PostActions(readAt: Date()).isRead)
        XCTAssertFalse(PostActions(readAt: nil).isRead)
    }

    func testPostActionsIsHiddenReflectsHiddenAt() {
        XCTAssertTrue(PostActions(hiddenAt: Date()).isHidden)
        XCTAssertFalse(PostActions(hiddenAt: nil).isHidden)
    }

    func testPostActionsIsSavedReflectsSavedAt() {
        XCTAssertTrue(PostActions(savedAt: Date()).isSaved)
        XCTAssertFalse(PostActions(savedAt: nil).isSaved)
    }

    func testPostActionsVoteDerivesFromVotedAtAndIsUpvote() {
        let now = Date()
        XCTAssertEqual(PostActions(votedAt: now, voteIsUpvote: true).vote, .up)
        XCTAssertEqual(PostActions(votedAt: now, voteIsUpvote: false).vote, .down)
        XCTAssertEqual(PostActions(votedAt: now, voteIsUpvote: nil).vote, .none)
        // votedAt nil means "never voted" regardless of voteIsUpvote.
        XCTAssertEqual(PostActions(votedAt: nil, voteIsUpvote: true).vote, .none)
        XCTAssertEqual(PostActions(votedAt: nil, voteIsUpvote: false).vote, .none)
        XCTAssertEqual(PostActions(votedAt: nil, voteIsUpvote: nil).vote, .none)
    }

    // MARK: - CommentActions

    func testCommentActionsIsSavedReflectsSavedAt() {
        XCTAssertTrue(CommentActions(savedAt: Date()).isSaved)
        XCTAssertFalse(CommentActions(savedAt: nil).isSaved)
    }

    func testCommentActionsVoteDerivesFromVotedAtAndIsUpvote() {
        let now = Date()
        XCTAssertEqual(CommentActions(votedAt: now, voteIsUpvote: true).vote, .up)
        XCTAssertEqual(CommentActions(votedAt: now, voteIsUpvote: false).vote, .down)
        XCTAssertEqual(CommentActions(votedAt: now, voteIsUpvote: nil).vote, .none)
        // votedAt nil means "never voted" regardless of voteIsUpvote.
        XCTAssertEqual(CommentActions(votedAt: nil, voteIsUpvote: true).vote, .none)
        XCTAssertEqual(CommentActions(votedAt: nil, voteIsUpvote: false).vote, .none)
        XCTAssertEqual(CommentActions(votedAt: nil, voteIsUpvote: nil).vote, .none)
    }

    // MARK: - CommunityActions

    func testCommunityActionsIsBlockedReflectsBlockedAt() {
        XCTAssertTrue(CommunityActions(blockedAt: Date()).isBlocked)
        XCTAssertFalse(CommunityActions(blockedAt: nil).isBlocked)
    }

    func testCommunityActionsIsModeratorReflectsBecameModeratorAt() {
        XCTAssertTrue(CommunityActions(becameModeratorAt: Date()).isModerator)
        XCTAssertFalse(CommunityActions(becameModeratorAt: nil).isModerator)
    }

    func testCommunityActionsResolvedFollowStateDefaultsToNotFollowing() {
        XCTAssertEqual(CommunityActions(followState: nil).resolvedFollowState, .notFollowing)
    }

    func testCommunityActionsResolvedFollowStateReturnsWrappedState() {
        XCTAssertEqual(CommunityActions(followState: .pending).resolvedFollowState, .pending)
        XCTAssertEqual(CommunityActions(followState: .approvalRequired).resolvedFollowState, .approvalRequired)
        XCTAssertEqual(CommunityActions(followState: .denied).resolvedFollowState, .denied)
        XCTAssertEqual(CommunityActions(followState: .accepted).resolvedFollowState, .accepted)
        XCTAssertEqual(CommunityActions(followState: .notFollowing).resolvedFollowState, .notFollowing)
    }

    // MARK: - PersonActions

    func testPersonActionsIsBlockedReflectsBlockedAt() {
        XCTAssertTrue(PersonActions(blockedAt: Date()).isBlocked)
        XCTAssertFalse(PersonActions(blockedAt: nil).isBlocked)
    }
}
