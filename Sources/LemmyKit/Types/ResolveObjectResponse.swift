//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct ResolveObjectResponse: Decodable {
    public let comment: CommentView?
    public let post: PostView?
    public let community: CommunityView?
    public let person: PersonView?

    public init(
        comment: CommentView? = nil,
        post: PostView? = nil,
        community: CommunityView? = nil,
        person: PersonView? = nil
    ) {
        self.comment = comment
        self.post = post
        self.community = community
        self.person = person
    }
}
