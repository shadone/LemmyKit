//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `PersonDetails` for a PieFed `PiefedPersonDetailsResponse` -- the same
/// profile + moderated-community-ids shape `personDetailsNeutralV3`/`personDetailsNeutralV4` build
/// inline in `LemmyApi+GetPersonDetailsNeutral.swift`.
///
/// `moderates` is `Optional` on `PiefedPersonDetailsResponse` purely for decode-safety (a future
/// PieFed drop of the key shouldn't break decoding) -- an absent list coalesces to `[]`, the same
/// "no signal" empty-collection default `MyUserV3Mapping.swift`'s own `moderates`/`follows`
/// defaults use.
package func neutralPersonDetails(fromPiefed response: PiefedPersonDetailsResponse) -> PersonDetails {
    PersonDetails(
        personView: neutralPersonView(fromPiefed: response.person_view),
        moderates: (response.moderates ?? []).map(\.community.id)
    )
}

/// Builds the neutral, single-page `Page<PostOrComment>` for a PieFed `PiefedPersonDetailsResponse`
/// -- the PieFed analogue of `LemmyApi+ListPersonContentNeutral.swift`'s v3 emulation
/// (`personContentNeutralV3`), factored out here as a reusable adapter rather than inlined at the
/// endpoint call site.
///
/// Like v3, PieFed has no dedicated combined post/comment feed endpoint at all -- its *only* source
/// is the `posts[]`/`comments[]` arrays inline in `GET /api/alpha/user`'s response (the same
/// endpoint `neutralPersonDetails(fromPiefed:)` reads), with no ordering between the two arrays.
/// This interleaves them by mapping each to `PostOrComment` and sorting the combined list by
/// `publishedAt` **descending**, so the result reads like a single recency-ordered feed -- the same
/// interleave rule `personContentNeutralV3` applies to v3's equivalent `posts`/`comments` arrays.
///
/// Unlike v3 (whose `getPersonDetails` takes `page`/`limit` and can synthesize a next-page cursor
/// from whether a full page came back), PieFed's `GET /api/alpha/user` accepts no
/// pagination parameters at all and its response carries no cursor of any kind -- so this always
/// returns a single, complete page (`nextPage`/`prevPage` both nil), the same "no cursor support at
/// all" convention `Page`'s own doc describes for a listing like `getComments`.
package func neutralPersonContentPage(fromPiefed response: PiefedPersonDetailsResponse) -> Page<PostOrComment> {
    let combined: [PostOrComment] =
        response.posts.map { .post(neutralPostView(fromPiefed: $0)) }
            + response.comments.map { .comment(neutralCommentView(fromPiefed: $0)) }

    let interleaved = combined.sorted { lhs, rhs in
        lhs.piefedInterleavePublishedAt > rhs.piefedInterleavePublishedAt
    }

    return Page(items: interleaved, nextPage: nil, prevPage: nil)
}

private extension PostOrComment {
    /// The item's publish date, used only to interleave PieFed's combined feed by recency -- not
    /// public API; callers read `.post`/`.comment` and their own `publishedAt`.
    var piefedInterleavePublishedAt: Date {
        switch self {
        case let .post(view): view.post.publishedAt
        case let .comment(view): view.comment.publishedAt
        }
    }
}
