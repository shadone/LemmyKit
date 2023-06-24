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
    public let icon: URL?
    public let banner: URL?
    public let description: String?
    public let actor_id: URL
    public let last_refreshed_at: Date
    public let inbox_url: URL
    public let private_key: String?
    public let public_key: String
    public let instance_id: InstanceId
}
