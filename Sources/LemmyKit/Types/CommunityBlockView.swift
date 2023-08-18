//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A community block.
public struct CommunityBlockView: Decodable {
    public let person: Person
    public let community: Community

    public init(
        person: Person,
        community: Community
    ) {
        self.person = person
        self.community = community
    }
}
