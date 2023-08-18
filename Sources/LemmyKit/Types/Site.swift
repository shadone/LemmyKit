//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct Site: Decodable {
    public let id: SiteId
    public let name: String
    public let sidebar: String?
    public let published: Date
    public let updated: Date?
    public let icon: LenientUrl?
    public let banner: LenientUrl?
    public let description: String?
    public let actor_id: URL
    public let last_refreshed_at: Date
    public let inbox_url: URL
    public let private_key: String?
    public let public_key: String
    public let instance_id: InstanceId

    public init(
        id: SiteId,
        name: String,
        sidebar: String? = nil,
        published: Date,
        updated: Date? = nil,
        icon: LenientUrl? = nil,
        banner: LenientUrl? = nil,
        description: String? = nil,
        actor_id: URL,
        last_refreshed_at: Date,
        inbox_url: URL,
        private_key: String? = nil,
        public_key: String,
        instance_id: InstanceId
    ) {
        self.id = id
        self.name = name
        self.sidebar = sidebar
        self.published = published
        self.updated = updated
        self.icon = icon
        self.banner = banner
        self.description = description
        self.actor_id = actor_id
        self.last_refreshed_at = last_refreshed_at
        self.inbox_url = inbox_url
        self.private_key = private_key
        self.public_key = public_key
        self.instance_id = instance_id
    }
}
