//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetSite: LemmyApiEndpoint {
    static let href: String = "site"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            auth: String? = nil
        ) {
            self.auth = auth
        }
    }

    public struct Response: Decodable {
        public let site_view: SiteView
        public let admins: [PersonView]
        public let version: String
        public let my_user: MyUserInfo?
        public let all_languages: [Language]
        public let discussion_languages: [LanguageId]
        public let taglines: [Tagline]
        public let custom_emojis: [CustomEmojiView]
    }
}
