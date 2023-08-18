//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPersonDetailsResponse: Decodable {
    public let person_view: PersonView
    public let comments: [CommentView]
    public let posts: [PostView]
    public let moderates: [CommunityModeratorView]

    public init(
        person_view: PersonView,
        comments: [CommentView],
        posts: [PostView],
        moderates: [CommunityModeratorView]
    ) {
        self.person_view = person_view
        self.comments = comments
        self.posts = posts
        self.moderates = moderates
    }
}
