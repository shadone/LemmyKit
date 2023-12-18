//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct MarkPostAsRead: LemmyApiEndpoint {
    static let href: String = "post/mark_as_read"
    static let method: HTTPMethod = .post

    public struct Request: Encodable {
        public let post_id: PostId?
        public let post_ids: [PostId]?

        public let read: Bool

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            post_id: PostId?,
            post_ids: [PostId]?,
            read: Bool,
            auth: String? = nil
        ) {
            self.post_id = post_id
            self.post_ids = post_ids
            self.read = read
            self.auth = auth
        }
    }

    public typealias Response = SuccessResponse
}
