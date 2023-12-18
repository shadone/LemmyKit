//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPosts: LemmyApiEndpoint {
    static let href: String = "post/list"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// The type of listing to fetch.
        public let type_: ListingType?

        /// Specifies how the posts in response should be ordered.
        public let sort: SortType?

        /// Pagination. The page number to fetch the results. This allows to fetch large data sets one page at a time.
        /// The first page is number 1.
        public let page: Int64?

        /// Pagination. Specifies the maximum number of results per page.
        ///
        /// Specifies the max number of posts to be fetched.
        ///
        /// - Note: This is server specific but in regular Lemmy install the default value is 10 and max is 50.
        public let limit: Int64?

        /// The community identifier to fetch posts from.
        public let community_id: CommunityId?

        /// The community name to fetch posts from.
        public let community_name: String?

        /// Whether to fetch only saved posts.
        public let saved_only: Bool?

        public let liked_only: Bool?

        public let disliked_only: Bool?

        public let page_cursor: PaginationCursor?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            type_: ListingType? = nil,
            sort: SortType? = nil,
            page: Int64? = nil,
            limit: Int64? = nil,
            community_id: CommunityId? = nil,
            community_name: String? = nil,
            saved_only: Bool? = nil,
            liked_only: Bool? = nil,
            disliked_only: Bool? = nil,
            page_cursor: PaginationCursor? = nil,
            auth: String? = nil
        ) {
            self.type_ = type_
            self.sort = sort
            self.page = page
            self.limit = limit
            self.community_id = community_id
            self.community_name = community_name
            self.saved_only = saved_only
            self.liked_only = liked_only
            self.disliked_only = disliked_only
            self.page_cursor = page_cursor
            self.auth = auth
        }
    }

    public typealias Response = GetPostsResponse
}
