//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// Wraps a v4 backend's opaque pagination cursor string in the neutral ``Cursor``, or nil if the
/// backend returned no cursor (there is no next/previous page from here).
package func neutralCursor(fromV4 cursor: LemmyKitV4Generated.Components.Schemas.PaginationCursor?) -> Cursor? {
    cursor.map { Cursor(rawValue: $0) }
}

/// Wraps a v3 backend's opaque pagination cursor string in the neutral ``Cursor``, or nil if the
/// backend returned no cursor. v3 has no reverse-paging cursor at all, so callers only ever pass
/// this a listing's `next_page` -- see ``Page/prevPage``, which a v3-backed `Page` always leaves
/// nil.
package func neutralCursor(fromV3 cursor: Components.Schemas.PaginationCursor?) -> Cursor? {
    cursor.map { Cursor(rawValue: $0) }
}

/// Builds a neutral, bidirectionally cursor-paginated `Page` from a v4 `PagedResponse_PostView_`,
/// mapping each item with `mapItem` (typically `neutralPostView(fromV4:)`).
package func neutralPage<Item>(
    fromV4 response: LemmyKitV4Generated.Components.Schemas.PagedResponse_PostView_,
    mapItem: (LemmyKitV4Generated.Components.Schemas.PostView) -> Item
) -> Page<Item> {
    Page(
        items: response.items.map(mapItem),
        nextPage: neutralCursor(fromV4: response.next_page),
        prevPage: neutralCursor(fromV4: response.prev_page)
    )
}

/// Builds a neutral, bidirectionally cursor-paginated `Page` from a v4
/// `PagedResponse_CommentView_`, mapping each item with `mapItem` (typically
/// `neutralCommentView(fromV4:)`).
package func neutralPage<Item>(
    fromV4 response: LemmyKitV4Generated.Components.Schemas.PagedResponse_CommentView_,
    mapItem: (LemmyKitV4Generated.Components.Schemas.CommentView) -> Item
) -> Page<Item> {
    Page(
        items: response.items.map(mapItem),
        nextPage: neutralCursor(fromV4: response.next_page),
        prevPage: neutralCursor(fromV4: response.prev_page)
    )
}

/// Builds a neutral, forward-only `Page` (`prevPage` always nil -- v3 has no reverse-paging
/// cursor) from a v3 listing's already-extracted items and optional `next_page` cursor, mapping
/// each item with `mapItem`. Pass `nextPage: nil` for a v3 listing with no cursor support at all
/// (for example `getComments`, whose `GetCommentsResponse` carries no cursor of any kind), which
/// always comes back as a single, complete page.
package func neutralPage<V3Item, Item>(
    fromV3 items: [V3Item],
    nextPage: Components.Schemas.PaginationCursor?,
    mapItem: (V3Item) -> Item
) -> Page<Item> {
    Page(
        items: items.map(mapItem),
        nextPage: neutralCursor(fromV3: nextPage),
        prevPage: nil
    )
}
