//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/custom_emoji_keyword.rs

/// A custom keyword for an emoji.
public struct CustomEmojiKeyword: Decodable {
    public let custom_emoji_id: CustomEmojiId
    public let keyword: String

    public init(
        custom_emoji_id: CustomEmojiId,
        keyword: String
    ) {
        self.custom_emoji_id = custom_emoji_id
        self.keyword = keyword
    }
}
