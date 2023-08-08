//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct ResolveObject: LemmyApiEndpoint {
    static let href: String = "resolve_object"
    static let method: HTTPMethod = .get

    public struct Request: Encodable {
        /// Search query.
        public let q: String

        /// Authentication token.
        public let auth: String?

        // MARK: Functions

        public init(
            q: String,
            auth: String? = nil
        ) {
            self.q = q
            self.auth = auth
        }
    }

    public typealias Response = ResolveObjectResponse
}
