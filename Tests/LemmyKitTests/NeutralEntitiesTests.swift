//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import XCTest
@testable import LemmyKit

/// Compact field-only coverage for the version-neutral entity structs in
/// `Sources/LemmyKit/Neutral/`: `Post`, `Comment`, `Community`, `Person`, `Site`. These are pure
/// value types with no derived behavior, so each test just confirms the memberwise `init` round
/// trips through `Identifiable` and `Equatable` correctly.
final class NeutralEntitiesTests: XCTestCase {
    // MARK: - Post

    func testPostIdentifiableAndEquatable() {
        let now = Date()
        let post = Post(
            id: 42,
            name: "Hello",
            body: "Body",
            url: "https://example.com",
            embedTitle: "Title",
            embedDescription: "Description",
            thumbnailUrl: "https://example.com/thumb.png",
            altText: "Alt",
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
            updatedAt: nil,
            newestCommentTimeAt: nil,
            score: 10,
            upvotes: 12,
            downvotes: 2,
            comments: 3
        )

        XCTAssertEqual(post.id, 42)

        let same = post
        XCTAssertEqual(post, same)

        let different = Post(
            id: post.id,
            name: post.name,
            body: post.body,
            url: post.url,
            embedTitle: post.embedTitle,
            embedDescription: post.embedDescription,
            thumbnailUrl: post.thumbnailUrl,
            altText: post.altText,
            creatorId: post.creatorId,
            communityId: post.communityId,
            apId: post.apId,
            local: post.local,
            nsfw: post.nsfw,
            removed: post.removed,
            deleted: post.deleted,
            locked: post.locked,
            featuredCommunity: post.featuredCommunity,
            featuredLocal: post.featuredLocal,
            languageId: post.languageId,
            publishedAt: post.publishedAt,
            updatedAt: post.updatedAt,
            newestCommentTimeAt: post.newestCommentTimeAt,
            score: post.score + 1,
            upvotes: post.upvotes,
            downvotes: post.downvotes,
            comments: post.comments
        )
        XCTAssertNotEqual(post, different)
    }

    // MARK: - Comment

    func testCommentIdentifiableAndEquatable() {
        let now = Date()
        let comment = Comment(
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
            updatedAt: nil,
            apId: "https://example.com/comment/7",
            local: true,
            score: 4,
            upvotes: 5,
            downvotes: 1,
            childCount: 0
        )

        XCTAssertEqual(comment.id, 7)

        let same = comment
        XCTAssertEqual(comment, same)

        // `Comment`'s stored properties are all `let`, so build a differing copy through the
        // memberwise init rather than in-place mutation.
        let differingCopy = Comment(
            id: comment.id,
            postId: comment.postId,
            creatorId: comment.creatorId,
            content: comment.content + "!",
            path: comment.path,
            removed: comment.removed,
            deleted: comment.deleted,
            distinguished: comment.distinguished,
            languageId: comment.languageId,
            publishedAt: comment.publishedAt,
            updatedAt: comment.updatedAt,
            apId: comment.apId,
            local: comment.local,
            score: comment.score,
            upvotes: comment.upvotes,
            downvotes: comment.downvotes,
            childCount: comment.childCount
        )
        XCTAssertNotEqual(comment, differingCopy)
    }

    // MARK: - Community

    func testCommunityIdentifiableAndEquatable() {
        let now = Date()
        let community = Community(
            id: 3,
            name: "technology",
            title: "Technology",
            sidebar: "Welcome",
            apId: "https://example.com/c/technology",
            iconUrl: nil,
            bannerUrl: nil,
            visibility: ._public,
            local: true,
            nsfw: false,
            postingRestrictedToMods: false,
            removed: false,
            deleted: false,
            publishedAt: now,
            updatedAt: nil,
            subscribers: 100,
            posts: 50,
            comments: 200
        )

        XCTAssertEqual(community.id, 3)

        let same = community
        XCTAssertEqual(community, same)

        let different = Community(
            id: community.id,
            name: community.name,
            title: community.title,
            sidebar: community.sidebar,
            apId: community.apId,
            iconUrl: community.iconUrl,
            bannerUrl: community.bannerUrl,
            visibility: .unlisted,
            local: community.local,
            nsfw: community.nsfw,
            postingRestrictedToMods: community.postingRestrictedToMods,
            removed: community.removed,
            deleted: community.deleted,
            publishedAt: community.publishedAt,
            updatedAt: community.updatedAt,
            subscribers: community.subscribers,
            posts: community.posts,
            comments: community.comments
        )
        XCTAssertNotEqual(community, different)
    }

    // MARK: - Person

    func testPersonIdentifiableAndEquatable() {
        let now = Date()
        let person = Person(
            id: 1,
            name: "alice",
            displayName: "Alice",
            avatarUrl: nil,
            bannerUrl: nil,
            bio: "Hi",
            apId: "https://example.com/u/alice",
            matrixUserId: nil,
            botAccount: false,
            deleted: false,
            local: true,
            publishedAt: now,
            updatedAt: nil,
            postCount: 5,
            commentCount: 10
        )

        XCTAssertEqual(person.id, 1)

        let same = person
        XCTAssertEqual(person, same)

        let different = Person(
            id: person.id,
            name: person.name,
            displayName: person.displayName,
            avatarUrl: person.avatarUrl,
            bannerUrl: person.bannerUrl,
            bio: person.bio,
            apId: person.apId,
            matrixUserId: person.matrixUserId,
            botAccount: person.botAccount,
            deleted: person.deleted,
            local: person.local,
            publishedAt: person.publishedAt,
            updatedAt: person.updatedAt,
            postCount: person.postCount + 1,
            commentCount: person.commentCount
        )
        XCTAssertNotEqual(person, different)
    }

    // MARK: - Site

    func testSiteIdentifiableAndEquatable() {
        let now = Date()
        let site = Site(
            id: 1,
            name: "Example",
            summary: "An example instance",
            sidebar: "Welcome",
            iconUrl: nil,
            bannerUrl: nil,
            apId: "https://example.com/",
            publishedAt: now,
            updatedAt: nil,
            posts: 1000,
            comments: 5000,
            communities: 20,
            users: 300,
            usersActiveDay: 10,
            usersActiveWeek: 50,
            usersActiveMonth: 100,
            usersActiveHalfYear: 150
        )

        XCTAssertEqual(site.id, 1)

        let same = site
        XCTAssertEqual(site, same)

        let different = Site(
            id: site.id,
            name: site.name,
            summary: site.summary,
            sidebar: site.sidebar,
            iconUrl: site.iconUrl,
            bannerUrl: site.bannerUrl,
            apId: site.apId,
            publishedAt: site.publishedAt,
            updatedAt: site.updatedAt,
            posts: site.posts,
            comments: site.comments,
            communities: site.communities,
            users: site.users,
            usersActiveDay: site.usersActiveDay + 1,
            usersActiveWeek: site.usersActiveWeek,
            usersActiveMonth: site.usersActiveMonth,
            usersActiveHalfYear: site.usersActiveHalfYear
        )
        XCTAssertNotEqual(site, different)
    }
}
