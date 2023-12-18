//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetComments: LemmyApiEndpoint {
    static let href: String = "comment/list"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// Specify the type of listing to fetch all comments in a given listing.
        /// E.g. fetch all comments for Subscribed communities.
        public let type_: ListingType?

        /// Specifies how the comments in response should be ordered.
        public let sort: CommentSortType?

        public let max_depth: Int32?

        /// Number of page to fetch. First page is number 1.
        public let page: Int64?

        /// Specifies the max number of posts to be fetched.
        /// This is server specific but in regular Lemmy install the default value is 10 and max is 50.
        public let limit: Int64?

        /// The community identifier to fetch comments from.
        public let community_id: CommunityId?

        /// The community name to fetch posts from.
        public let community_name: String?

        /// Specify the post identifier to fetch comments for a given post.
        public let post_id: PostId?

        public let parent_id: CommentId?

        /// Whether to fetch only saved comments.
        public let saved_only: Bool?

        public let liked_only: Bool?

        public let disliked_only: Bool?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            type_: ListingType? = nil,
            sort: CommentSortType? = nil,
            max_depth: Int32? = nil,
            page: Int64? = nil,
            limit: Int64? = nil,
            community_id: CommunityId? = nil,
            community_name: String? = nil,
            post_id: PostId? = nil,
            parent_id: CommentId? = nil,
            saved_only: Bool? = nil,
            liked_only: Bool? = nil,
            disliked_only: Bool? = nil,
            auth: String? = nil
        ) {
            self.type_ = type_
            self.sort = sort
            self.max_depth = max_depth
            self.page = page
            self.limit = limit
            self.community_id = community_id
            self.community_name = community_name
            self.post_id = post_id
            self.parent_id = parent_id
            self.saved_only = saved_only
            self.liked_only = liked_only
            self.disliked_only = disliked_only
            self.auth = auth
        }
    }

    public typealias Response = GetCommentsResponse
}
