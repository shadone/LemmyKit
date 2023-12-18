//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum PostListingMode: String, Codable, CustomStringConvertible {
    /// A compact, list-type view.
    case list = "List"
    /// A larger card-type view.
    case card = "Card"
    /// A smaller card-type view, usually with images as thumbnails
    case smallCard = "SmallCard"

    public var description: String { rawValue }
}
