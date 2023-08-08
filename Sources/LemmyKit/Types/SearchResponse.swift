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
}
