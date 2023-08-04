//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPost: LemmyApiEndpoint {
    static let href: String = "post"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// The post identifier to fetch.
        public let id: PostId?

        /// The comment identifier to fetch.
        public let comment_id: CommentId?

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            id: PostId? = nil,
            comment_id: CommentId? = nil,
            auth: String? = nil
        ) {
            self.id = id
            self.comment_id = comment_id
            self.auth = auth
        }
    }

    public typealias Response = GetPostResponse
}
