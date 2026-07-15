//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Searches Lemmy for `query` and returns the version-neutral ``SearchResults``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as
    /// ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``: the v3 client's
    /// `search` mapped "up" via `neutralSearchResults(fromV3:)`, or the v4 client's `Search`
    /// mapped near-directly via `neutralSearchResults(fromV4:)`.
    ///
    /// - Parameters:
    ///   - query: the search term; must be non-empty. Sent as v3's `q` / v4's `search_term`.
    ///   - type: which kind of result to return.
    ///   - sort: result ordering, or `nil` (the default) to let the server define the order. **v4's
    ///     `Search` operation has no sort parameter at all**, so v4 always uses the server's default
    ///     ordering. On v3, `nil` omits the `sort` query param (the server then applies its own
    ///     default, which is `Hot`); a non-nil value is honored via `v3SortType(fromNeutral:timeRange:)`
    ///     (the same fold `getPostsNeutral` uses). Passing `nil` therefore yields the same
    ///     server-defined ordering on both backends -- prefer it unless a caller needs a specific v3 sort.
    ///   - timeRange: the top-N time window to pair with `sort == .top`, matching
    ///     ``getPostsNeutral(listingType:sort:communityId:timeRange:showNsfw:pageCursor:)``'s semantics: on
    ///     v3 it folds into the fused `SortType` bucket (alongside `sort`, so it has no effect if
    ///     `sort` is ignored -- see `sort` above), on v4 it is sent as-is via
    ///     `time_range_seconds` regardless of `sort`.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page. **v3 has no cursor support for search at all** -- v3's `search` only offers
    ///     classic page/limit pagination, so on a v3 backend this parameter is accepted for
    ///     signature symmetry with v4 but ignored, and the returned `SearchResults` always has
    ///     `nextPage`/`prevPage` both nil.
    /// - Returns: the neutral `SearchResults` matching the given query, type, and sort.
    func searchNeutral(
        query: String,
        type: SearchType,
        sort: PostSort? = nil,
        timeRange: TimeRange? = nil,
        pageCursor: Cursor? = nil
    ) async throws -> SearchResults {
        switch apiVersion {
        case .v3:
            try await searchNeutralV3(query: query, type: type, sort: sort, timeRange: timeRange)
        case .v4:
            try await searchNeutralV4(query: query, type: type, timeRange: timeRange, pageCursor: pageCursor)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "search")
        }
    }
}

/// Folds the neutral `SearchType` into v3's `SearchType`. Every neutral case has a direct v3
/// equivalent; v3's `.Url` case (filter to link posts whose url matches the query) has no
/// neutral equivalent and is unreachable from this fold -- see `Neutral/SearchType.swift`'s
/// header.
private func v3SearchType(fromNeutral type: SearchType) -> Components.Schemas.SearchType {
    switch type {
    case .all: .All
    case .comments: .Comments
    case .posts: .Posts
    case .communities: .Communities
    case .persons: .Users
    }
}

/// Direct, 1:1 mapping from neutral `SearchType` to v4's `SearchType` -- v4 dropped `.Url`
/// (superseded on v4 by the separate `post_url_only` boolean, which this neutral surface does not
/// yet expose) and added `.multi_communities` (out of scope for this phase, see
/// `Neutral/SearchResults.swift`'s header); neither is represented by the neutral enum.
private func v4SearchType(
    fromNeutral type: SearchType
) -> LemmyKitV4Generated.Components.Schemas.SearchType {
    switch type {
    case .all: .all
    case .comments: .comments
    case .posts: .posts
    case .communities: .communities
    case .persons: .users
    }
}

private extension LemmyApi {
    /// v3 path: calls the v3 generated client's `search` operation directly (the same
    /// request-building and response-branching shape as the pre-neutral
    /// ``search(query:type:sort:listingType:community:creatorID:postTitleOnly:page:limit:)``),
    /// then maps the extracted response up to the neutral shape. v3's `search` has no cursor
    /// parameter of any kind, so `pageCursor` is not forwarded and the result's cursors are always
    /// nil (see `neutralSearchResults(fromV3:)`).
    func searchNeutralV3(
        query: String,
        type: SearchType,
        sort: PostSort?,
        timeRange: TimeRange?
    ) async throws -> SearchResults {
        let response: Operations.search.Output
        do {
            response = try await client.search(query: .init(
                q: query,
                type_: v3SearchType(fromNeutral: type),
                // nil sort omits the query param so the server applies its own default (Hot),
                // matching v4 (whose Search has no sort param at all).
                sort: sort.map { v3SortType(fromNeutral: $0, timeRange: timeRange) }
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralSearchResults(fromV3: json)
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 path: calls the v4 generated client's `Search` operation, then maps the extracted v4
    /// response near-directly to the neutral shape. Like `getPostNeutral(id:)`'s v4 path, v4's
    /// `Search` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`. v4's `Search` has no `sort` parameter at all, so `sort` is not forwarded
    /// here -- see ``searchNeutral(query:type:sort:timeRange:pageCursor:)``'s doc.
    func searchNeutralV4(
        query: String,
        type: SearchType,
        timeRange: TimeRange?,
        pageCursor: Cursor?
    ) async throws -> SearchResults {
        let response: LemmyKitV4Generated.Operations.Search.Output
        do {
            response = try await v4Client.Search(query: .init(
                page_cursor: pageCursor?.rawValue,
                time_range_seconds: timeRange?.seconds,
                type_: v4SearchType(fromNeutral: type),
                search_term: query
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralSearchResults(fromV4: json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
