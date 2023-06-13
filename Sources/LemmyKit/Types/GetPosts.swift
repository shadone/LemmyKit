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
        public let type_: ListingType?
        public let sort: SortType?
        public let page: Int?
        public let limit: Int?
        public let community_id: CommunityId?
        public let community_name: String?
        public let saved_only: Bool?
    }

    public struct Response: Decodable {
        public let posts: [PostView]
    }
}
