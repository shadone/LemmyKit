//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CreatePostLike: LemmyApiEndpoint {
    static let href: String = "post/like"
    static let method: HTTPMethod = .post

    public struct Request: Encodable {
        /// Specify the post identifier to vote on.
        public let post_id: PostId

        /// Score must be -1, 0, or 1.
        public let score: Int16

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            post_id: PostId,
            score: Int16,
            auth: String? = nil
        ) {
            self.post_id = post_id
            self.score = score
            self.auth = auth
        }
    }

    public typealias Response = PostResponse
}
