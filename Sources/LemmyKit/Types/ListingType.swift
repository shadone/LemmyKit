//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum ListingType: String, Codable, CustomStringConvertible {
    /// Content from your own site, as well as all connected / federated sites.
    case all = "All"
    /// Content from your site only.
    case local = "Local"
    /// Content only from communities you've subscribed to.
    case subscribed = "Subscribed"
    /// Content that you can moderate (because you are a moderator of the community it is posted to)
    case moderatorView = "ModeratorView"

    public var description: String { rawValue }
}
