//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedResolveObjectResponse` to the neutral `ResolvedObject` -- the "emulate
/// upward" adapter direction, the same pattern as `ResolvedObjectV3Mapping.swift`.
///
/// PieFed's `PiefedResolveObjectResponse` carries the resolved object as four independent
/// optionals (`post`/`comment`/`community`/`person`) rather than a discriminated union, mirroring
/// v3's shape -- and PieFed's own live behavior (spot-checked against `piefed.social`) confirms
/// exactly one is ever non-nil per response. This checks them in the same fixed priority order as
/// the v3/v4 adapters (post, then comment, then community, then person) and returns the first one
/// present. Returns nil if all four are nil, which is what happens when the query couldn't be
/// resolved to anything.
package func neutralResolvedObject(fromPiefed response: PiefedResolveObjectResponse) -> ResolvedObject? {
    if let post = response.post {
        return .post(neutralPostView(fromPiefed: post))
    }
    if let comment = response.comment {
        return .comment(neutralCommentView(fromPiefed: comment))
    }
    if let community = response.community {
        return .community(neutralCommunityView(fromPiefed: community))
    }
    if let person = response.person {
        return .person(neutralPersonView(fromPiefed: person))
    }
    return nil
}
