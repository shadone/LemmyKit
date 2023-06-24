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

        /// Number of page to fetch. First page is number 1.
        public let page: Int?

        /// Specifies the max number of posts to be fetched.
        /// This is server specific but in regular Lemmy install the default value is 10 and max is 50.
        public let limit: Int?

        /// The community identifier to fetch posts from.
        public let community_id: CommunityId?

        /// The community name to fetch posts from.
        public let community_name: String?

        /// Whether to fetch only saved posts.
        public let saved_only: Bool?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            type_: ListingType? = nil,
            sort: SortType? = nil,
            page: Int? = nil,
            limit: Int? = nil,
            community_id: CommunityId? = nil,
            community_name: String? = nil,
            saved_only: Bool? = nil,
            auth: String? = nil
        ) {
            self.type_ = type_
            self.sort = sort
            self.page = page
            self.limit = limit
            self.community_id = community_id
            self.community_name = community_name
            self.saved_only = saved_only
            self.auth = auth
        }
    }

    public typealias Response = GetPostsResponse
}
