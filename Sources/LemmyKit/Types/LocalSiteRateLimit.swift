//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/local_site_rate_limit.rs

public struct LocalSiteRateLimit: Decodable {
    public let id: Int32
    public let local_site_id: LocalSiteId
    public let message: Int32
    public let message_per_second: Int32
    public let post: Int32
    public let post_per_second: Int32
    public let register: Int32
    public let register_per_second: Int32
    public let image: Int32
    public let image_per_second: Int32
    public let comment: Int32
    public let comment_per_second: Int32
    public let search: Int32
    public let search_per_second: Int32
    public let published: Date
    public let updated: Date?
}
