//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

protocol LemmyApiEndpoint {
    static var href: String { get }
    static var method: HTTPMethod { get }

    associatedtype Request: Encodable
    associatedtype Response: Decodable
}
