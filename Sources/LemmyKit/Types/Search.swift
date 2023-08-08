//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct Search: LemmyApiEndpoint {
    static let href: String = "search"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// Search query.
        public let q: String

        public let community_id: CommunityId?

        public let community_name: String?

        public let creator_id: PersonId?

        public let type_: SearchType?

        /// Specifies how the search results in response should be ordered.
        public let sort: SortType?

        /// The type of listing to fetch.
        public let listing_type: ListingType?

        /// Pagination. The page number to fetch the results. This allows to fetch large data sets one page at a time.
        /// The first page is number 1.
        public let page: Int64?

        /// Pagination. Specifies the maximum number of results per page.
        ///
        /// Specifies the max number of posts to be fetched.
        ///
        /// - Note: This is server specific but in regular Lemmy install the default value is 10 and max is 50.
        public let limit: Int64?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            q: String,
            community_id: CommunityId? = nil,
            community_name: String? = nil,
            creator_id: PersonId? = nil,
            type_: SearchType? = nil,
            sort: SortType? = nil,
            listing_type: ListingType? = nil,
            page: Int64? = nil,
            limit: Int64? = nil,
            auth: String? = nil
        ) {
            self.q = q
            self.community_id = community_id
            self.community_name = community_name
            self.creator_id = creator_id
            self.type_ = type_
            self.sort = sort
            self.listing_type = listing_type
            self.page = page
            self.limit = limit
            self.auth = auth
        }
    }

    public typealias Response = SearchResponse
}
