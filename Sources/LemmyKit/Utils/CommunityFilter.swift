//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Identifies a community either by its numeric id or by its name.
///
/// Accepted anywhere the API can look a community up either way, such as
/// ``LemmyApi/getComments(community:sort:filter:page:limit:)`` and
/// ``LemmyApi/getPosts(community:sort:filter:showHidden:showRead:showNSFW:page:limit:)``.
public enum CommunityFilter: Sendable {
    /// Identify the community by its numeric id.
    case id(Components.Schemas.CommunityID)
    /// Identify the community by name: a bare name (`gnome`) for a community
    /// local to the queried instance, or a fully-qualified name
    /// (`gnome@lemmy.world`) for a remote one.
    case name(String)

    var id: Components.Schemas.CommunityID? {
        if case let .id(communityID) = self { communityID } else { nil }
    }

    var name: String? {
        if case let .name(string) = self { string } else { nil }
    }
}
