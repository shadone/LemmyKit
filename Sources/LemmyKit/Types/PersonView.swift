//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_views_actor/src/structs.rs

public struct PersonView: Decodable {
    public let person: Person
    public let counts: PersonAggregates

    public init(
        person: Person,
        counts: PersonAggregates
    ) {
        self.person = person
        self.counts = counts
    }
}
