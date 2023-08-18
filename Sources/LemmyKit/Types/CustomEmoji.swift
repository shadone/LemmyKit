//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/custom_emoji.rs

/// A custom emoji.
public struct CustomEmoji: Decodable {
    public let id: CustomEmojiId
    public let local_site_id: LocalSiteId
    public let shortcode: String
    public let image_url: LenientUrl
    public let alt_text: String
    public let category: String
    public let published: Date
    public let updated: Date?

    public init(
        id: CustomEmojiId,
        local_site_id: LocalSiteId,
        shortcode: String,
        image_url: LenientUrl,
        alt_text: String,
        category: String,
        published: Date,
        updated: Date? = nil
    ) {
        self.id = id
        self.local_site_id = local_site_id
        self.shortcode = shortcode
        self.image_url = image_url
        self.alt_text = alt_text
        self.category = category
        self.published = published
        self.updated = updated
    }
}
