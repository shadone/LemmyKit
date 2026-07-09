//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Maps a v4 `Components.Schemas.ResolveObjectView` to the neutral `ResolvedObject` -- the
/// near-direct adapter direction (see `PostViewV4Mapping.swift`'s header for the general shape of
/// this direction).
///
/// v4's `ResolveObjectView` is a discriminated union (`anyOf` on a `type_` tag merged onto the
/// matching payload) of five variants -- post, comment, person, community, and
/// `multi_community` -- of which the server only ever sets one on a given response; the
/// generator's decoder (`ResolveObjectView.init(from:)`) tries all five and requires at least one
/// to succeed, so an "nothing resolved" response is impossible to represent on the wire for v4
/// (unlike v3's four-optionals shape, where all four can legitimately be nil). The
/// `multi_community` variant (a community-of-communities) has no neutral counterpart -- see
/// `Neutral/ResolvedObject.swift`'s header -- so a response that only resolves a
/// `MultiCommunityView` returns nil here, the same as v3's "nothing resolved" case.
package func neutralResolvedObject(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.ResolveObjectView
) -> ResolvedObject? {
    if let value1 = v4.value1 {
        return .post(neutralPostView(fromV4: value1.value2))
    }
    if let value2 = v4.value2 {
        return .comment(neutralCommentView(fromV4: value2.value2))
    }
    if let value3 = v4.value3 {
        return .person(neutralPersonView(fromV4: value3.value2))
    }
    if let value4 = v4.value4 {
        return .community(neutralCommunityView(fromV4: value4.value2))
    }
    // value5 (multi_community) has no neutral counterpart -- see this function's header.
    return nil
}
