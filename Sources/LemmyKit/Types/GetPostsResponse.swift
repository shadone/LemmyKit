//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPostsResponse: Decodable {
    public let posts: [PostView]

    public init(posts: [PostView]) {
        self.posts = posts
    }
}
