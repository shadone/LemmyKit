//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPersonMentions: LemmyApiEndpoint {
    static let href: String = "user/mentions"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        public let sort: CommentSortType?
        public let unread_only: Bool?

        /// Pagination. The page number to fetch the results. This allows to fetch large data sets one page at a time.
        /// The first page is number 1.
        public let page: Int64?

        /// Pagination. Specifies the maximum number of results per page.
        public let limit: Int64?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            sort: CommentSortType? = nil,
            unread_only: Bool? = nil,
            page: Int64? = nil,
            limit: Int64? = nil,
            auth: String? = nil
        ) {
            self.sort = sort
            self.unread_only = unread_only
            self.page = page
            self.limit = limit
            self.auth = auth
        }
    }

    public typealias Response = GetPersonMentionsResponse
}
