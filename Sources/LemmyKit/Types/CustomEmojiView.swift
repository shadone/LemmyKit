//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views/src/structs.rs

public struct CustomEmojiView: Decodable {
    public let custom_emoji: CustomEmoji
    public let keywords: [CustomEmojiKeyword]

    public init(
        custom_emoji: CustomEmoji,
        keywords: [CustomEmojiKeyword]
    ) {
        self.custom_emoji = custom_emoji
        self.keywords = keywords
    }
}
