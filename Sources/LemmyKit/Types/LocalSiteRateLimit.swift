//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/local_site_rate_limit.rs

/// Rate limits for your site. Given in count / length of time.
public struct LocalSiteRateLimit: Decodable {
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
    public let import_user_settings: Int32
    public let import_user_settings_per_second: Int32

    public init(
        local_site_id: LocalSiteId,
        message: Int32,
        message_per_second: Int32,
        post: Int32,
        post_per_second: Int32,
        register: Int32,
        register_per_second: Int32,
        image: Int32,
        image_per_second: Int32,
        comment: Int32,
        comment_per_second: Int32,
        search: Int32,
        search_per_second: Int32,
        published: Date,
        updated: Date? = nil,
        import_user_settings: Int32,
        import_user_settings_per_second: Int32
    ) {
        self.local_site_id = local_site_id
        self.message = message
        self.message_per_second = message_per_second
        self.post = post
        self.post_per_second = post_per_second
        self.register = register
        self.register_per_second = register_per_second
        self.image = image
        self.image_per_second = image_per_second
        self.comment = comment
        self.comment_per_second = comment_per_second
        self.search = search
        self.search_per_second = search_per_second
        self.published = published
        self.updated = updated
        self.import_user_settings = import_user_settings
        self.import_user_settings_per_second = import_user_settings_per_second
    }
}
