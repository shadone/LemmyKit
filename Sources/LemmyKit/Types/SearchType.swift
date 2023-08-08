//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum SearchType: String, Codable {
    case all = "All"
    case comments = "Comments"
    case posts = "Posts"
    case communities = "Communities"
    case users = "Users"
    case url = "Url"
}

extension SearchType: CustomStringConvertible {
    public var description: String { rawValue }
}
