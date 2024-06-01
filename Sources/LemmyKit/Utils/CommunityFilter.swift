//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum CommunityFilter {
    case id(Components.Schemas.CommunityID)
    case name(String)

    var id: Components.Schemas.CommunityID? {
        if case let .id(communityID) = self {
            return communityID
        }
        return nil
    }

    var name: String? {
        if case let .name(string) = self {
            return string
        }
        return nil
    }
}
