//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views_actor/src/structs.rs

/// A community follower.
public struct CommunityFollowerView: Decodable {
    public let community: Community
    public let follower: Person

    public init(
        community: Community,
        follower: Person
    ) {
        self.community = community
        self.follower = follower
    }
}
