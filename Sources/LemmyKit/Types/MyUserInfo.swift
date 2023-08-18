//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/api_common/src/site.rs

public struct MyUserInfo: Decodable {
    public let local_user_view: LocalUserView
    public let follows: [CommunityFollowerView]
    public let moderates: [CommunityModeratorView]
    public let community_blocks: [CommunityBlockView]
    public let person_blocks: [PersonBlockView]
    public let discussion_languages: [LanguageId]

    public init(
        local_user_view: LocalUserView,
        follows: [CommunityFollowerView],
        moderates: [CommunityModeratorView],
        community_blocks: [CommunityBlockView],
        person_blocks: [PersonBlockView],
        discussion_languages: [LanguageId]
    ) {
        self.local_user_view = local_user_view
        self.follows = follows
        self.moderates = moderates
        self.community_blocks = community_blocks
        self.person_blocks = person_blocks
        self.discussion_languages = discussion_languages
    }
}
