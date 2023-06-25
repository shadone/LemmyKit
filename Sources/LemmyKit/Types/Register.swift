//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct Register: LemmyApiEndpoint {
    static let href: String = "user/register"
    static let method: HTTPMethod = .post

    public struct Request: Encodable {
        public let username: String
        public let password: String
        public let password_verify: String
        public let show_nsfw: Bool
        public let email: String?
        public let captcha_uuid: String?
        public let captcha_answer: String?
        public let honeypot: String?
        public let answer: String?

        // MARK: Functions

        public init(
            username: String,
            password: String,
            password_verify: String,
            show_nsfw: Bool,
            email: String? = nil,
            captcha_uuid: String? = nil,
            captcha_answer: String? = nil,
            honeypot: String? = nil,
            answer: String? = nil
        ) {
            self.username = username
            self.password = password
            self.password_verify = password_verify
            self.show_nsfw = show_nsfw
            self.email = email
            self.captcha_uuid = captcha_uuid
            self.captcha_answer = captcha_answer
            self.honeypot = honeypot
            self.answer = answer
        }
    }

    public typealias Response = GetPostsResponse
}
