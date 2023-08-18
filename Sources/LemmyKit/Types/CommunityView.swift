//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CommunityView: Decodable {
    public let community: Community
    public let subscribed: SubscribedType
    public let blocked: Bool
    public let counts: CommunityAggregates

    public init(
        community: Community,
        subscribed: SubscribedType,
        blocked: Bool,
        counts: CommunityAggregates
    ) {
        self.community = community
        self.subscribed = subscribed
        self.blocked = blocked
        self.counts = counts
    }
}
