//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct Login: LemmyApiEndpoint {
    static let href: String = "user/login"
    static let method: HTTPMethod = .post

    public struct Request: Encodable {
        public let username_or_email: String
        public let password: String
        public let totp_2fa_token: String?

        // MARK: Functions

        public init(
            username_or_email: String,
            password: String,
            totp_2fa_token: String? = nil
        ) {
            self.username_or_email = username_or_email
            self.password = password
            self.totp_2fa_token = totp_2fa_token
        }
    }

    public typealias Response = LoginResponse
}
