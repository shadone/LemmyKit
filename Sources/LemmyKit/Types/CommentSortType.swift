//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum CommentSortType:
    String,
    Codable, CaseIterable,
    Identifiable, CustomStringConvertible
{
    case hot = "Hot"
    case top = "Top"
    case new = "New"
    case old = "Old"
    case controversial = "Controversial"

    public var id: String { rawValue }
    public var description: String { rawValue }
}
