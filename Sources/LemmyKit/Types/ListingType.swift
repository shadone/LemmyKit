//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum ListingType: String, Encodable, CustomStringConvertible {
    case all = "All"
    case local = "Local"
    case subscribed = "Subscribed"

    public var description: String { rawValue }
}