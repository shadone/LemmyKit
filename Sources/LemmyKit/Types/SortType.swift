//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum SortType: String, Encodable {
    case active = "Active"
    case hot = "Hot"
    case new = "New"
    case old = "Old"
    case topDay = "TopDay"
    case topWeek = "TopWeek"
    case topMonth = "TopMonth"
    case topYear = "TopYear"
    case topAll = "TopAll"
    case mostComments = "MostComments"
    case newComments = "NewComments"
}

extension SortType: CustomStringConvertible {
    public var description: String { rawValue }
}
