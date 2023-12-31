//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CreateCommentLike: LemmyApiEndpoint {
    static let href: String = "comment/like"
    static let method: HTTPMethod = .post

    public struct Request: Encodable {
        /// Specify the comment identifier to vote on.
        public let comment_id: CommentId

        /// Score must be -1, 0, or 1.
        public let score: ScoreAction

        // MARK: Functions

        public init(
            comment_id: CommentId,
            score: ScoreAction
        ) {
            self.comment_id = comment_id
            self.score = score
        }
    }

    public typealias Response = CommentResponse
}
