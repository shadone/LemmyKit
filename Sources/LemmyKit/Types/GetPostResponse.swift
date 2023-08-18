//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPostResponse: Decodable {
    public let post_view: PostView
    public let community_view: CommunityView
    public let moderators: [CommunityModeratorView]
    public let cross_posts: [PostView]

    public init(
        post_view: PostView,
        community_view: CommunityView,
        moderators: [CommunityModeratorView],
        cross_posts: [PostView]
    ) {
        self.post_view = post_view
        self.community_view = community_view
        self.moderators = moderators
        self.cross_posts = cross_posts
    }
}
