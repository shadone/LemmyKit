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
}
