//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum SubscribedType: String, Decodable {
    case subscribed = "Subscribed"
    case notSubscribed = "NotSubscribed"
    case pending = "Pending"
}
