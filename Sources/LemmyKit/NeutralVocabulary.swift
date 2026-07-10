//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// A neutral namespace over the OpenAPI-generated `Components.Schemas.*` vocabulary.
///
/// This is stage 1 of the neutral-surface migration: consumers of LemmyKit should prefer
/// `Lemmy.PostView` / `Lemmy.PostID` over the verbose `Components.Schemas.PostView`. The
/// vocabulary lives under this caseless-enum namespace (rather than bare top-level
/// typealiases) so that common nouns like `Post`, `Comment`, and `Person` do not pollute
/// consumers' global scope — `import LemmyKit` must not shadow, say, Swift Testing's
/// `Comment` type. The DTO members with a hand-written neutral counterpart (`PostView`,
/// `CommentView`, `CommunityView`, `PersonView`, `PrivateMessageView`, `Post`, `Comment`,
/// `Community`, `Person`, `Site`) now alias that neutral type (`Sources/LemmyKit/Neutral/`)
/// instead of the generated schema; the remaining DTO members (aggregates, other views,
/// responses without a neutral equivalent) and all identifier/enum members remain simple
/// aliases to `Components.Schemas.*`. The existing `Components.Schemas.*` surface remains
/// untouched and fully usable by the old v3 wrappers.
public enum Lemmy {
    // MARK: - Identifiers

    public typealias PostID = Components.Schemas.PostID
    public typealias CommentID = Components.Schemas.CommentID
    public typealias PersonID = Components.Schemas.PersonID
    public typealias CommunityID = Components.Schemas.CommunityID
    public typealias PersonMentionID = Components.Schemas.PersonMentionID
    public typealias CommentReplyID = Components.Schemas.CommentReplyID
    public typealias PrivateMessageID = Components.Schemas.PrivateMessageID

    // MARK: - Sort, listing, and type enums

    public typealias SortType = Components.Schemas.SortType
    public typealias CommentSortType = Components.Schemas.CommentSortType
    public typealias ListingType = Components.Schemas.ListingType
    public typealias SubscribedType = Components.Schemas.SubscribedType
    public typealias SearchType = Components.Schemas.SearchType
    public typealias PostFeatureType = Components.Schemas.PostFeatureType
    public typealias RegistrationMode = Components.Schemas.RegistrationMode

    // MARK: - Views

    public typealias PostView = LemmyKit.PostView
    public typealias CommentView = LemmyKit.CommentView
    public typealias CommunityView = LemmyKit.CommunityView
    public typealias PersonView = LemmyKit.PersonView
    public typealias PrivateMessageView = LemmyKit.PrivateMessageView
    public typealias PersonMentionView = Components.Schemas.PersonMentionView
    public typealias CommentReplyView = Components.Schemas.CommentReplyView
    public typealias CommunityFollowerView = Components.Schemas.CommunityFollowerView
    public typealias ModRemoveCommentView = Components.Schemas.ModRemoveCommentView
    public typealias SiteView = Components.Schemas.SiteView

    // MARK: - Core models

    public typealias Post = LemmyKit.Post
    public typealias Comment = LemmyKit.Comment
    public typealias CommentReply = Components.Schemas.CommentReply
    public typealias Community = LemmyKit.Community
    public typealias Person = LemmyKit.Person
    public typealias PrivateMessage = Components.Schemas.PrivateMessage
    public typealias MyUserInfo = Components.Schemas.MyUserInfo
    public typealias Site = LemmyKit.Site
    public typealias LocalSite = Components.Schemas.LocalSite
    public typealias LocalSiteRateLimit = Components.Schemas.LocalSiteRateLimit
    public typealias LocalUser = Components.Schemas.LocalUser

    // MARK: - Aggregates (per-entity counts)

    public typealias PostAggregates = Components.Schemas.PostAggregates
    public typealias CommentAggregates = Components.Schemas.CommentAggregates
    public typealias CommunityAggregates = Components.Schemas.CommunityAggregates
    public typealias PersonAggregates = Components.Schemas.PersonAggregates
    public typealias SiteAggregates = Components.Schemas.SiteAggregates

    // MARK: - Responses

    public typealias GetSiteResponse = Components.Schemas.GetSiteResponse
    public typealias ErrorResponse = Components.Schemas.ErrorResponse
    public typealias CommunityResponse = Components.Schemas.CommunityResponse
    public typealias CommentReplyResponse = Components.Schemas.CommentReplyResponse
    public typealias CommentReportResponse = Components.Schemas.CommentReportResponse
    public typealias PostReportResponse = Components.Schemas.PostReportResponse
    public typealias PostResponse = Components.Schemas.PostResponse
    public typealias CommentResponse = Components.Schemas.CommentResponse
    public typealias LoginResponse = Components.Schemas.LoginResponse
    public typealias SearchResponse = Components.Schemas.SearchResponse
    public typealias GetPersonDetailsResponse = Components.Schemas.GetPersonDetailsResponse
    public typealias ResolveObjectResponse = Components.Schemas.ResolveObjectResponse
    public typealias PrivateMessagesResponse = Components.Schemas.PrivateMessagesResponse
    public typealias PrivateMessageResponse = Components.Schemas.PrivateMessageResponse
    public typealias GetRepliesResponse = Components.Schemas.GetRepliesResponse
    public typealias GetPersonMentionsResponse = Components.Schemas.GetPersonMentionsResponse
    public typealias GetCommunityResponse = Components.Schemas.GetCommunityResponse
    public typealias GetPostsResponse = Components.Schemas.GetPostsResponse
    public typealias GetPostResponse = Components.Schemas.GetPostResponse
    public typealias GetCommentsResponse = Components.Schemas.GetCommentsResponse
    public typealias ListCommunitiesResponse = Components.Schemas.ListCommunitiesResponse
    public typealias GetUnreadCountResponse = Components.Schemas.GetUnreadCountResponse
    public typealias SuccessResponse = Components.Schemas.SuccessResponse
    public typealias BlockPersonResponse = Components.Schemas.BlockPersonResponse
    public typealias BlockCommunityResponse = Components.Schemas.BlockCommunityResponse
    public typealias BanFromCommunityResponse = Components.Schemas.BanFromCommunityResponse
}
