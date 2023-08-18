//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views/src/structs.rs

public struct LocalUserView: Decodable {
    public let local_user: LocalUser
    public let person: Person
    public let counts: PersonAggregates

    public init(
        local_user: LocalUser,
        person: Person,
        counts: PersonAggregates
    ) {
        self.local_user = local_user
        self.person = person
        self.counts = counts
    }
}
