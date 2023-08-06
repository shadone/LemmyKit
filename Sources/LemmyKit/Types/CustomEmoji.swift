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
}
