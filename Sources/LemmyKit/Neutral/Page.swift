//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// A single page of results from a bidirectional cursor-paginated listing.
///
/// v4 listings return this shape natively (`items`/`next_page`/`prev_page`). v3 backends have
/// no notion of a previous-page cursor, so the V3 adapter always leaves `prevPage` nil and
/// synthesizes `nextPage` itself (see `Cursor`); listings with no v3 cursor support at all
/// (for example comment lists) come back as a single page with `nextPage` also nil.
public struct Page<Item: Sendable>: Sendable {
    /// The items in this page, in server order.
    public let items: [Item]

    /// A cursor to fetch the next page, or nil if this is the last page.
    public let nextPage: Cursor?

    /// A cursor to fetch the previous page, or nil if this is the first page (always nil on a
    /// v3-backed listing).
    public let prevPage: Cursor?

    public init(items: [Item], nextPage: Cursor?, prevPage: Cursor?) {
        self.items = items
        self.nextPage = nextPage
        self.prevPage = prevPage
    }

    /// True if a subsequent page can be fetched via `nextPage`.
    public var hasNextPage: Bool {
        nextPage != nil
    }

    /// True if a preceding page can be fetched via `prevPage`.
    public var hasPrevPage: Bool {
        prevPage != nil
    }
}

extension Page: Equatable where Item: Equatable { }
