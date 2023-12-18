//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPersonDetails: LemmyApiEndpoint {
    static let href: String = "user"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        public let person_id: PersonId?
        public let username: String?
        public let sort: SortType?

        /// Pagination. The page number to fetch the results. This allows to fetch large data sets one page at a time.
        /// The first page is number 1.
        public let page: Int64?

        /// Pagination. Specifies the maximum number of results per page.
        public let limit: Int64?

        public let community_id: CommunityId?

        /// Whether to fetch only saved posts.
        public let saved_only: Bool?

        // MARK: Functions

        public init(
            person_id: PersonId? = nil,
            username: String? = nil,
            sort: SortType? = nil,
            page: Int64? = nil,
            limit: Int64? = nil,
            community_id: CommunityId? = nil,
            saved_only: Bool? = nil
        ) {
            self.person_id = person_id
            self.username = username
            self.sort = sort
            self.page = page
            self.limit = limit
            self.community_id = community_id
            self.saved_only = saved_only
        }
    }

    public typealias Response = GetPersonDetailsResponse
}
