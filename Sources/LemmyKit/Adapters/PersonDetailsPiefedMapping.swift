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
/// PieFed's `GET /api/alpha/user` does document `page` (default 1) and `limit` (default 20) query
/// params, same as v3's `getPersonDetails` -- but the current `PiefedClient` wrapper doesn't send
/// them yet (a client-wiring gap left for the endpoint task, which will mirror
/// `LemmyApi+ListPersonContentNeutral.swift`'s v3 emulation: send explicit `page`/`limit` and
/// synthesize a `nextPage` cursor whenever a returned count equals the limit). Until that lands,
/// this adapter only ever sees a single, unpaginated response with no cursor of any kind, so it
/// always returns a single, complete page (`nextPage`/`prevPage` both nil).
package func neutralPersonContentPage(fromPiefed response: PiefedPersonDetailsResponse) -> Page<PostOrComment> {
    let combined: [PostOrComment] =
        response.posts.map { .post(neutralPostView(fromPiefed: $0)) }
            + response.comments.map { .comment(neutralCommentView(fromPiefed: $0)) }

    let interleaved = combined.sorted { lhs, rhs in
        lhs.publishedAt > rhs.publishedAt
    }

    return Page(items: interleaved, nextPage: nil, prevPage: nil)
}
