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

        /// Authentication token.
        public let auth: String?
    }

    public struct Response: Decodable {
        public let comments: [CommentView]
    }
}
