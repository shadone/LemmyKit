//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPostsResponse: Decodable {
    public let posts: [PostView]

    public let next_page: PaginationCursor?

    public init(
        posts: [PostView],
        next_page: PaginationCursor?
    ) {
        self.posts = posts
        self.next_page = next_page
    }
}
