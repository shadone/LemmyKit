//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a page of a person's combined post/comment feed and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PostOrComment``.
    ///
    /// v4 serves this as its own paginated endpoint, `ListPersonContent`, entirely separate from
    /// `GetPersonDetails` (see ``personDetailsNeutral(personId:)``'s doc for the split). v3 has
    /// no such endpoint at all -- v3's *only* source for a person's posts/comments is the
    /// `comments[]`/`posts[]` arrays inline in its `getPersonDetails` response, the same
    /// endpoint `personDetailsNeutral` calls. This method's v3 path re-fetches that endpoint
    /// (rather than `personDetailsNeutral` caching and sharing the arrays) so it can page through
    /// them independently of the profile lookup, exactly mirroring how the v4 split lets a
    /// caller re-page the feed without re-fetching the profile.
    ///
    /// ## The v3 emulation: interleave and pagination
    ///
    /// v3 keeps posts and comments in two separate arrays with no combined ordering between
    /// them; v4's combined feed is a single list sorted by recency regardless of item type. To
    /// emulate that, the v3 path:
    /// 1. Fetches one v3 page of `getPersonDetails` (page/limit derived from `pageCursor`, see
    ///    below).
    /// 2. Wraps every returned post/comment in `PostOrComment`.
    /// 3. **Interleaves** the combined list by sorting on each item's `publishedAt`
    ///    (`PostView.post.publishedAt`/`CommentView.comment.publishedAt`) **descending**, so the
    ///    result reads like a single recency-ordered feed even though it was assembled from two
    ///    separately-paginated v3 lists.
    ///
    /// v3's `getPersonDetails` has no cursor of any kind (only int `page`/`limit`), so this
    /// method synthesizes an opaque `Cursor` that encodes the next v3 page number as a bare
    /// integer string -- an internal encoding detail (see `Cursor`'s own doc) that must never be
    /// parsed or constructed by a caller. Because v3 applies `page`/`limit` to the posts and
    /// comments lists independently, whether "more content" exists on the next v3 page can't be
    /// known for certain from this page alone; `nextPage` is synthesized whenever *either* list
    /// came back a full page (`count == limit`), since running out of one type doesn't mean the
    /// other has too. This is a conservative, first-pass emulation: each v3 page is interleaved
    /// and returned independently, so an item that logically belongs "between" two pages by
    /// publish date is not re-sorted across the page boundary -- see `Cursor`'s doc for the
    /// general caveat that a v3-backed listing's cursor is an implementation detail, not a
    /// promise of a single global ordering.
    ///
    /// - Parameters:
    ///   - personId: the person whose content to fetch.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`; nil fetches the first
    ///     page. `prevPage` is always nil on a v3 backend (no reverse-paging cursor at all, see
    ///     `Page`'s doc).
    /// - Returns: a `Page` of the neutral `PostOrComment`s for the given person.
    func personContentNeutral(
        personId: Int64,
        pageCursor: Cursor? = nil
    ) async throws -> Page<PostOrComment> {
        switch apiVersion {
        case .v3:
            try await personContentNeutralV3(personId: personId, pageCursor: pageCursor)
        case .v4:
            try await personContentNeutralV4(personId: personId, pageCursor: pageCursor)
        case .piefed:
            try await personContentNeutralPiefed(personId: personId, pageCursor: pageCursor)
        }
    }
}

/// The v3 page/limit this emulation requests when synthesizing its own opaque cursor -- see
/// ``LemmyApi/personContentNeutral(personId:pageCursor:)``'s doc. Sent explicitly (rather than
/// leaving it to the server's default) so `nextPage` synthesis can reliably compare a returned
/// list's count against this exact value.
private let v3PersonContentPageLimit: Int64 = 10

/// Decodes the v3-emulation's synthesized page-number cursor (see
/// ``LemmyApi/personContentNeutral(personId:pageCursor:)``'s doc), defaulting to the first page
/// when `cursor` is nil or unparseable.
private func v3PersonContentPage(fromCursor cursor: Cursor?) -> Int64 {
    cursor.flatMap { Int64($0.rawValue) } ?? 1
}

/// Synthesizes the v3-emulation's next-page cursor: present whenever `postsCount` or
/// `commentsCount` came back a full `v3PersonContentPageLimit`-sized page (either list may still
/// have more even if the other has run out), nil otherwise.
private func v3PersonContentNextPageCursor(page: Int64, postsCount: Int, commentsCount: Int) -> Cursor? {
    guard Int64(postsCount) == v3PersonContentPageLimit || Int64(commentsCount) == v3PersonContentPageLimit else {
        return nil
    }
    return Cursor(rawValue: String(page + 1))
}

/// The PieFed page/limit this emulation requests when synthesizing its own opaque cursor -- the
/// PieFed analogue of `v3PersonContentPageLimit` above, same value and same reasoning (sent
/// explicitly so `nextPage` synthesis can reliably compare a returned list's count against it).
private let piefedPersonContentPageLimit = 10

/// Decodes the PieFed-emulation's synthesized page-number cursor -- the PieFed analogue of
/// `v3PersonContentPage(fromCursor:)` above, defaulting to the first page when `cursor` is nil or
/// unparseable.
private func piefedPersonContentPage(fromCursor cursor: Cursor?) -> Int {
    cursor.flatMap { Int($0.rawValue) } ?? 1
}

/// Synthesizes the PieFed-emulation's next-page cursor -- the PieFed analogue of
/// `v3PersonContentNextPageCursor(page:postsCount:commentsCount:)` above: present whenever
/// `postsCount` or `commentsCount` came back a full `piefedPersonContentPageLimit`-sized page
/// (either list may still have more even if the other has run out), nil otherwise.
private func piefedPersonContentNextPageCursor(page: Int, postsCount: Int, commentsCount: Int) -> Cursor? {
    guard postsCount == piefedPersonContentPageLimit || commentsCount == piefedPersonContentPageLimit else {
        return nil
    }
    return Cursor(rawValue: String(page + 1))
}

private extension LemmyApi {
    /// v3 path: the emulation described in ``LemmyApi/personContentNeutral(personId:pageCursor:)``'s
    /// doc -- fetch one v3 `getPersonDetails` page, map its inline `posts[]`/`comments[]` to
    /// `PostOrComment`, and interleave them by `publishedAt` descending.
    func personContentNeutralV3(personId: Int64, pageCursor: Cursor?) async throws -> Page<PostOrComment> {
        let personID = try v3PersonID(personId)
        let page = v3PersonContentPage(fromCursor: pageCursor)

        let response: Operations.getPersonDetails.Output
        do {
            response = try await client.getPersonDetails(query: .init(
                person_id: personID,
                page: page,
                limit: v3PersonContentPageLimit
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                let combined: [PostOrComment] =
                    json.posts.map { .post(neutralPostView(fromV3: $0)) }
                        + json.comments.map { .comment(neutralCommentView(fromV3: $0)) }
                let interleaved = combined.sorted {
                    $0.publishedAt > $1.publishedAt
                }

                return Page(
                    items: interleaved,
                    nextPage: v3PersonContentNextPageCursor(
                        page: page,
                        postsCount: json.posts.count,
                        commentsCount: json.comments.count
                    ),
                    // v3 has no reverse-paging cursor -- see `Page`'s doc.
                    prevPage: nil
                )
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

    /// v4 path: calls the v4 generated client's `ListPersonContent` operation, then maps each
    /// extracted item to the neutral `PostOrComment` via the throwing
    /// `neutralPostOrComment(fromV4:)` (see `PostCommentCombinedV4Mapping.swift`). v4's
    /// `ListPersonContent` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func personContentNeutralV4(personId: Int64, pageCursor: Cursor?) async throws -> Page<PostOrComment> {
        let response: LemmyKitV4Generated.Operations.ListPersonContent.Output
        do {
            response = try await v4Client.ListPersonContent(query: .init(
                page_cursor: pageCursor?.rawValue,
                person_id: personId
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return try neutralPage(fromV4: json) { try neutralPostOrComment(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: the same emulation ``personContentNeutralV3(personId:pageCursor:)`` applies to
    /// v3, since PieFed likewise has no dedicated combined post/comment feed endpoint -- its only
    /// source is the `posts[]`/`comments[]` arrays inline in `GET /api/alpha/user`'s response
    /// (`PiefedClient.getPersonDetails(personId:includeContent:page:limit:)`, called here with
    /// `includeContent: true`). Sends explicit `page`/`limit` (`piefedPersonContentPageLimit`) so
    /// `nextPage` synthesis can compare a returned count against them, reuses
    /// `neutralPersonContentPage(fromPiefed:)` for the interleave (mapping + recency sort -- see
    /// that adapter's doc for why cursor synthesis is NOT baked into it), then rebuilds the
    /// returned `Page` with the synthesized cursor from `piefedPersonContentNextPageCursor`.
    func personContentNeutralPiefed(personId: Int64, pageCursor: Cursor?) async throws -> Page<PostOrComment> {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "personContent") }

        let page = piefedPersonContentPage(fromCursor: pageCursor)
        let response = try await piefedClient.getPersonDetails(
            personId: personId,
            includeContent: true,
            page: page,
            limit: piefedPersonContentPageLimit
        )

        let interleaved = neutralPersonContentPage(fromPiefed: response)
        return Page(
            items: interleaved.items,
            nextPage: piefedPersonContentNextPageCursor(
                page: page,
                postsCount: response.posts.count,
                commentsCount: response.comments.count
            ),
            // PieFed has no reverse-paging cursor -- see `Page`'s doc.
            prevPage: nil
        )
    }
}
