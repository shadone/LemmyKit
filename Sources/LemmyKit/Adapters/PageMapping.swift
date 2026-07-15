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

/// Builds a neutral, bidirectionally cursor-paginated `Page` from a v4
/// `PagedResponse_CommunityView_`, mapping each item with `mapItem` (typically
/// `neutralCommunityView(fromV4:)`).
package func neutralPage<Item>(
    fromV4 response: LemmyKitV4Generated.Components.Schemas.PagedResponse_CommunityView_,
    mapItem: (LemmyKitV4Generated.Components.Schemas.CommunityView) -> Item
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

/// Builds a neutral, bidirectionally cursor-paginated `Page` from a v4
/// `PagedResponse_PostCommentCombinedView_`, mapping each item with a throwing `mapItem`
/// (`neutralPostOrComment(fromV4:)` -- throwing because the generator's `anyOf` shape can, in
/// principle, decode with neither branch present; see `PostCommentCombinedV4Mapping.swift`).
package func neutralPage<Item>(
    fromV4 response: LemmyKitV4Generated.Components.Schemas.PagedResponse_PostCommentCombinedView_,
    mapItem: (LemmyKitV4Generated.Components.Schemas.PostCommentCombinedView) throws -> Item
) rethrows -> Page<Item> {
    try Page(
        items: response.items.map(mapItem),
        nextPage: neutralCursor(fromV4: response.next_page),
        prevPage: neutralCursor(fromV4: response.prev_page)
    )
}

/// Builds a neutral, bidirectionally cursor-paginated `Page` from a v4
/// `PagedResponse_NotificationView_`, mapping each item with a throwing `mapItem`
/// (`neutralNotificationView(fromV4:)` -- throwing for the same reason as the
/// `PostCommentCombinedView` overload above: the generator's `anyOf` shape can, in principle,
/// decode with none of its four branches present; see `NotificationV4Mapping.swift`).
package func neutralPage<Item>(
    fromV4 response: LemmyKitV4Generated.Components.Schemas.PagedResponse_NotificationView_,
    mapItem: (LemmyKitV4Generated.Components.Schemas.NotificationView) throws -> Item
) rethrows -> Page<Item> {
    try Page(
        items: response.items.map(mapItem),
        nextPage: neutralCursor(fromV4: response.next_page),
        prevPage: neutralCursor(fromV4: response.prev_page)
    )
}

/// Wraps a PieFed backend's bare `next_page` string in the neutral ``Cursor``, or nil if PieFed
/// returned no cursor (there is no next page from here). PieFed's `/api/alpha` listings carry a
/// bare `String?` rather than v3/v4's typed `PaginationCursor` schema type, so this takes the
/// wire value directly rather than going through `neutralCursor(fromV3:)`/`neutralCursor(fromV4:)`.
package func neutralCursor(fromPiefed cursor: String?) -> Cursor? {
    cursor.map { Cursor(rawValue: $0) }
}

/// Builds a neutral, forward-only `Page` (`prevPage` always nil -- PieFed has no reverse-paging
/// cursor, matching v3) from a PieFed listing's already-extracted items and optional `next_page`
/// string, mapping each item with `mapItem`.
package func neutralPage<PiefedItem, Item>(
    fromPiefed items: [PiefedItem],
    nextPage: String?,
    mapItem: (PiefedItem) -> Item
) -> Page<Item> {
    Page(
        items: items.map(mapItem),
        nextPage: neutralCursor(fromPiefed: nextPage),
        prevPage: nil
    )
}
