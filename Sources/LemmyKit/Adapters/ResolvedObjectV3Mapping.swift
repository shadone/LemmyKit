//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a v3 `Components.Schemas.ResolveObjectResponse` to the neutral `ResolvedObject` -- the
/// "emulate upward" adapter direction (see `PostViewV3Mapping.swift`'s header for the general
/// shape of this direction).
///
/// v3's `ResolveObjectResponse` carries the resolved object as four independent optionals
/// (`post`/`comment`/`community`/`person`) rather than a discriminated union, and the spec never
/// documents more than one being set on a given response -- but nothing in the generated type
/// enforces that. This checks them in a fixed priority order (post, then comment, then community,
/// then person) and returns the first one present, matching v4's own type-tag ordering (see
/// `ResolvedObjectV4Mapping.swift`). Returns nil if all four are nil, which is what happens when
/// the query couldn't be resolved to anything.
package func neutralResolvedObject(
    fromV3 v3: Components.Schemas.ResolveObjectResponse
) -> ResolvedObject? {
    if let post = v3.post {
        return .post(neutralPostView(fromV3: post))
    }
    if let comment = v3.comment {
        return .comment(neutralCommentView(fromV3: comment))
    }
    if let community = v3.community {
        return .community(neutralCommunityView(fromV3: community))
    }
    if let person = v3.person {
        return .person(neutralPersonView(fromV3: person))
    }
    return nil
}
