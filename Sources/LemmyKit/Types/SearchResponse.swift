//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct SearchResponse: Decodable {
    public let type_: SearchType
    public let comments: [CommentView]
    public let posts: [PostView]
    public let communities: [CommunityView]
    public let users: [PersonView]

    public init(
        type_: SearchType,
        comments: [CommentView],
        posts: [PostView],
        communities: [CommunityView],
        users: [PersonView]
    ) {
        self.type_ = type_
        self.comments = comments
        self.posts = posts
        self.communities = communities
        self.users = users
    }
}
