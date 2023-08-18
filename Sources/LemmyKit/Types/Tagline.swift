//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/tagline.rs

/// A tagline, shown at the top of your site.
public struct Tagline: Decodable {
    public let id: Int32
    public let local_site_id: LocalSiteId
    public let content: String
    public let published: Date
    public let updated: Date?

    public init(
        id: Int32,
        local_site_id: LocalSiteId,
        content: String,
        published: Date,
        updated: Date? = nil
    ) {
        self.id = id
        self.local_site_id = local_site_id
        self.content = content
        self.published = published
        self.updated = updated
    }
}
