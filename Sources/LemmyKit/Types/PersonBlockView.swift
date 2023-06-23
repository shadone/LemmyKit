//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A person block.
public struct PersonBlockView: Decodable {
    public let person: Person
    public let target: Person
}
