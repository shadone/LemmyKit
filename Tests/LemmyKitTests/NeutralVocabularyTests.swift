//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

/// Proves that each member of the `Lemmy` namespace resolves to the intended generated
/// `Components.Schemas.*` type, so a mis-alias (e.g. aliasing `Lemmy.PostID` to the wrong
/// schema) fails to compile or fails an assertion.
final class NeutralVocabularyTests: XCTestCase {
    // MARK: - Identifiers

    /// The ID members are all `Swift.Int32`, so a `.self ==` check would be a near-tautology
    /// across all of them; these compile-level proofs pin each alias to its own generated
    /// parameter/schema type instead.
    func testIdentifierAliases() {
        let _: Lemmy.PostID = Components.Schemas.PostID(0)
        let _: Lemmy.CommentID = Components.Schemas.CommentID(0)
        let _: Lemmy.PersonID = Components.Schemas.PersonID(0)
        let _: Lemmy.CommunityID = Components.Schemas.CommunityID(0)
        let _: Lemmy.PersonMentionID = Components.Schemas.PersonMentionID(0)
        let _: Lemmy.CommentReplyID = Components.Schemas.CommentReplyID(0)
        let _: Lemmy.PrivateMessageID = Components.Schemas.PrivateMessageID(0)
    }

    // MARK: - Sort, listing, and type enums

    /// Uses a real generated case per enum so the alias is pinned to the intended type
    /// rather than merely to "some enum with the right name".
    func testEnumAliases() {
        let _: Lemmy.SortType = Components.Schemas.SortType.Active
        let _: Lemmy.CommentSortType = Components.Schemas.CommentSortType.Hot
        let _: Lemmy.ListingType = Components.Schemas.ListingType.All
        let _: Lemmy.SubscribedType = Components.Schemas.SubscribedType.Subscribed
        let _: Lemmy.SearchType = Components.Schemas.SearchType.All
        let _: Lemmy.PostFeatureType = Components.Schemas.PostFeatureType.Local
        let _: Lemmy.RegistrationMode = Components.Schemas.RegistrationMode.Open
    }

    // MARK: - Views

    func testViewAliasesResolveToGeneratedTypes() {
        XCTAssertTrue(Lemmy.PostView.self == Components.Schemas.PostView.self)
        XCTAssertTrue(Lemmy.SiteView.self == Components.Schemas.SiteView.self)
        XCTAssertTrue(Lemmy.CommentView.self == Components.Schemas.CommentView.self)
        XCTAssertTrue(Lemmy.CommunityView.self == Components.Schemas.CommunityView.self)
        XCTAssertTrue(Lemmy.PersonView.self == Components.Schemas.PersonView.self)
        XCTAssertTrue(Lemmy.PrivateMessageView.self == Components.Schemas.PrivateMessageView.self)
        XCTAssertTrue(Lemmy.PersonMentionView.self == Components.Schemas.PersonMentionView.self)
        XCTAssertTrue(Lemmy.CommentReplyView.self == Components.Schemas.CommentReplyView.self)
        XCTAssertTrue(Lemmy.CommunityFollowerView.self == Components.Schemas.CommunityFollowerView.self)
        XCTAssertTrue(Lemmy.ModRemoveCommentView.self == Components.Schemas.ModRemoveCommentView.self)
    }

    // MARK: - Core models

    func testModelAliasesResolveToGeneratedTypes() {
        XCTAssertTrue(Lemmy.Post.self == Components.Schemas.Post.self)
        XCTAssertTrue(Lemmy.Comment.self == Components.Schemas.Comment.self)
        XCTAssertTrue(Lemmy.CommentReply.self == Components.Schemas.CommentReply.self)
        XCTAssertTrue(Lemmy.Community.self == Components.Schemas.Community.self)
        XCTAssertTrue(Lemmy.Person.self == Components.Schemas.Person.self)
        XCTAssertTrue(Lemmy.PrivateMessage.self == Components.Schemas.PrivateMessage.self)
        XCTAssertTrue(Lemmy.MyUserInfo.self == Components.Schemas.MyUserInfo.self)
        XCTAssertTrue(Lemmy.Site.self == Components.Schemas.Site.self)
        XCTAssertTrue(Lemmy.LocalSite.self == Components.Schemas.LocalSite.self)
        XCTAssertTrue(Lemmy.LocalSiteRateLimit.self == Components.Schemas.LocalSiteRateLimit.self)
        XCTAssertTrue(Lemmy.LocalUser.self == Components.Schemas.LocalUser.self)
    }

    // MARK: - Aggregates

    func testAggregateAliasesResolveToGeneratedTypes() {
        XCTAssertTrue(Lemmy.PostAggregates.self == Components.Schemas.PostAggregates.self)
        XCTAssertTrue(Lemmy.CommentAggregates.self == Components.Schemas.CommentAggregates.self)
        XCTAssertTrue(Lemmy.CommunityAggregates.self == Components.Schemas.CommunityAggregates.self)
        XCTAssertTrue(Lemmy.PersonAggregates.self == Components.Schemas.PersonAggregates.self)
        XCTAssertTrue(Lemmy.SiteAggregates.self == Components.Schemas.SiteAggregates.self)
    }

    // MARK: - Responses

    func testResponseAliasesResolveToGeneratedTypes() {
        XCTAssertTrue(Lemmy.GetSiteResponse.self == Components.Schemas.GetSiteResponse.self)
        XCTAssertTrue(Lemmy.ErrorResponse.self == Components.Schemas.ErrorResponse.self)
        XCTAssertTrue(Lemmy.CommunityResponse.self == Components.Schemas.CommunityResponse.self)
        XCTAssertTrue(Lemmy.CommentReplyResponse.self == Components.Schemas.CommentReplyResponse.self)
        XCTAssertTrue(Lemmy.CommentReportResponse.self == Components.Schemas.CommentReportResponse.self)
        XCTAssertTrue(Lemmy.PostReportResponse.self == Components.Schemas.PostReportResponse.self)
        XCTAssertTrue(Lemmy.PostResponse.self == Components.Schemas.PostResponse.self)
        XCTAssertTrue(Lemmy.CommentResponse.self == Components.Schemas.CommentResponse.self)
        XCTAssertTrue(Lemmy.LoginResponse.self == Components.Schemas.LoginResponse.self)
        XCTAssertTrue(Lemmy.SearchResponse.self == Components.Schemas.SearchResponse.self)
        XCTAssertTrue(Lemmy.GetPersonDetailsResponse.self == Components.Schemas.GetPersonDetailsResponse.self)
        XCTAssertTrue(Lemmy.ResolveObjectResponse.self == Components.Schemas.ResolveObjectResponse.self)
        XCTAssertTrue(Lemmy.PrivateMessagesResponse.self == Components.Schemas.PrivateMessagesResponse.self)
        XCTAssertTrue(Lemmy.PrivateMessageResponse.self == Components.Schemas.PrivateMessageResponse.self)
        XCTAssertTrue(Lemmy.GetRepliesResponse.self == Components.Schemas.GetRepliesResponse.self)
        XCTAssertTrue(Lemmy.GetPersonMentionsResponse.self == Components.Schemas.GetPersonMentionsResponse.self)
        XCTAssertTrue(Lemmy.GetCommunityResponse.self == Components.Schemas.GetCommunityResponse.self)
        XCTAssertTrue(Lemmy.GetPostsResponse.self == Components.Schemas.GetPostsResponse.self)
        XCTAssertTrue(Lemmy.GetPostResponse.self == Components.Schemas.GetPostResponse.self)
        XCTAssertTrue(Lemmy.GetCommentsResponse.self == Components.Schemas.GetCommentsResponse.self)
        XCTAssertTrue(Lemmy.ListCommunitiesResponse.self == Components.Schemas.ListCommunitiesResponse.self)
        XCTAssertTrue(Lemmy.GetUnreadCountResponse.self == Components.Schemas.GetUnreadCountResponse.self)
        XCTAssertTrue(Lemmy.SuccessResponse.self == Components.Schemas.SuccessResponse.self)
        XCTAssertTrue(Lemmy.BlockPersonResponse.self == Components.Schemas.BlockPersonResponse.self)
        XCTAssertTrue(Lemmy.BlockCommunityResponse.self == Components.Schemas.BlockCommunityResponse.self)
        XCTAssertTrue(Lemmy.BanFromCommunityResponse.self == Components.Schemas.BanFromCommunityResponse.self)
    }
}
