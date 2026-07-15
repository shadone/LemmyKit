//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// The fixed page size the v3 path requests from `getPrivateMessages`. v3 pages by page/limit, so
/// this endpoint asks for a constant slice and synthesizes a cursor from the returned count (see
/// `getPrivateMessagesNeutralV3`). A short page (fewer than this many items) means the last page.
private let privateMessagesNeutralV3PageSize: Int64 = 50

/// The fixed page size the PieFed path requests from `PiefedClient.getPrivateMessages` -- the
/// PieFed analogue of `privateMessagesNeutralV3PageSize` above, same reasoning (see
/// `getPrivateMessagesNeutralPiefed`'s doc): PieFed's private-message list carries no cursor of
/// any kind, so this asks for a constant slice and synthesizes a cursor from the returned count.
private let privateMessagesNeutralPiefedPageSize = 20

public extension LemmyApi {
    /// Fetches a page of the viewer's private messages and returns the version-neutral,
    /// cursor-paginated ``Page`` of ``PrivateMessageListItem``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the same shape as
    /// ``getSavedPostsNeutral(sort:timeRange:pageCursor:)``: on v3 the legacy
    /// `getPrivateMessages(unreadOnly:page:limit:)` mapped "up" via `neutralPrivateMessageView(fromV3:)`;
    /// on v4 the unified `ListNotifications` endpoint filtered to `type_: .private_message`, mapped via
    /// `neutralPrivateMessageView(fromV4:)`.
    ///
    /// Each item pairs the neutral ``PrivateMessageView`` with its read state, because the view
    /// itself carries no read flag (see ``PrivateMessageListItem``'s doc). `isRead` comes from v3's
    /// `private_message.read` or v4's `notification.read`.
    ///
    /// **Pagination differs by backend:**
    /// - **v3** has no native cursor. This requests a fixed page size (see
    ///   `privateMessagesNeutralV3PageSize`) and *synthesizes* a cursor: `pageCursor` is decoded
    ///   back to a 1-based page number (nil, or an unparseable cursor, means page 1), and the
    ///   returned `nextPage` is a cursor for the next page number **only when the page came back
    ///   full** — a full page implies there may be more, a short or empty page is the end. `prevPage`
    ///   is always nil (v3 has no reverse-paging cursor; see ``Page/prevPage``).
    /// - **v4** returns real opaque `next_page`/`prev_page` cursors, forwarded unchanged.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread messages, false for all. Forwarded to v3's
    ///     `getPrivateMessages` and to v4's `ListNotifications` `unread_only` filter.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page. On v3 this is an internally-synthesized page-number cursor (see above); on v4
    ///     it is the server's native cursor. PieFed follows the same page-number-cursor synthesis as
    ///     v3 -- see `getPrivateMessagesNeutralPiefed`'s doc.
    /// - Returns: a `Page` of ``PrivateMessageListItem``s, each a message view plus its read state.
    func getPrivateMessagesNeutral(
        unreadOnly: Bool = false,
        pageCursor: Cursor? = nil
    ) async throws -> Page<PrivateMessageListItem> {
        switch apiVersion {
        case .v3:
            try await getPrivateMessagesNeutralV3(unreadOnly: unreadOnly, pageCursor: pageCursor)
        case .v4:
            try await getPrivateMessagesNeutralV4(unreadOnly: unreadOnly, pageCursor: pageCursor)
        case .piefed:
            try await getPrivateMessagesNeutralPiefed(unreadOnly: unreadOnly, pageCursor: pageCursor)
        }
    }
}

/// Maps a v4 notification item to a ``PrivateMessageListItem``, or nil if it is not a private
/// message. Since the request filters to `type_: .private_message`, non-PM items shouldn't appear;
/// nil-ing them defensively drops any that slip through rather than mis-mapping them (the private
/// message payload is v4's `NotificationData` `value3` branch — see `NotificationV4Mapping.swift`).
private func privateMessageListItem(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.NotificationView
) -> PrivateMessageListItem? {
    guard let privateMessage = v4.data.value3 else { return nil }
    return PrivateMessageListItem(
        view: neutralPrivateMessageView(fromV4: privateMessage.value2),
        isRead: v4.notification.read
    )
}

private extension LemmyApi {
    /// v3 path: calls the legacy `getPrivateMessages` with a fixed page size and a page number
    /// decoded from `pageCursor` (nil or unparseable → page 1), maps each `PrivateMessageView` up
    /// via `neutralPrivateMessageView(fromV3:)`, and reads `private_message.read` for each item's
    /// `isRead`. Synthesizes `nextPage` as a cursor for the next page number only when the page came
    /// back full (`count == privateMessagesNeutralV3PageSize`); a short/empty page ends the listing.
    /// `prevPage` is always nil (v3 has no reverse-paging cursor).
    func getPrivateMessagesNeutralV3(
        unreadOnly: Bool,
        pageCursor: Cursor?
    ) async throws -> Page<PrivateMessageListItem> {
        let page = pageCursor.flatMap { Int64($0.rawValue) } ?? 1

        let response = try await getPrivateMessages(
            unreadOnly: unreadOnly,
            page: page,
            limit: privateMessagesNeutralV3PageSize
        )

        let items = response.private_messages.map { view in
            PrivateMessageListItem(
                view: neutralPrivateMessageView(fromV3: view),
                isRead: view.private_message.read
            )
        }

        let nextPage = Int64(items.count) == privateMessagesNeutralV3PageSize
            ? Cursor(rawValue: "\(page + 1)")
            : nil

        return Page(items: items, nextPage: nextPage, prevPage: nil)
    }

    /// v4 path: calls the unified `ListNotifications` filtered to `type_: .private_message`,
    /// forwarding `unread_only` and the native `page_cursor`, then maps each notification's private
    /// message payload via `privateMessageListItem(fromV4:)` (reading `notification.read` for
    /// `isRead`) and forwards the server's native `next_page`/`prev_page` via `neutralCursor(fromV4:)`.
    /// Non-PM items are dropped (see `privateMessageListItem(fromV4:)`). Like `getPostsNeutral`'s v4
    /// path, `ListNotifications` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func getPrivateMessagesNeutralV4(
        unreadOnly: Bool,
        pageCursor: Cursor?
    ) async throws -> Page<PrivateMessageListItem> {
        let response: LemmyKitV4Generated.Operations.ListNotifications.Output
        do {
            response = try await v4Client.ListNotifications(query: .init(
                page_cursor: pageCursor?.rawValue,
                unread_only: unreadOnly,
                type_: .init(value1: .private_message)
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return Page(
                    items: json.items.compactMap(privateMessageListItem(fromV4:)),
                    nextPage: neutralCursor(fromV4: json.next_page),
                    prevPage: neutralCursor(fromV4: json.prev_page)
                )
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.getPrivateMessages(unreadOnly:page:limit:)` with a fixed
    /// page size (see `privateMessagesNeutralPiefedPageSize`) and a page number decoded from
    /// `pageCursor` (nil or unparseable → page 1), maps each `PiefedPrivateMessageView` via
    /// `neutralPrivateMessageListItem(fromPiefed:)` (which already pairs the view with its
    /// `private_message.read` for `isRead` -- see that adapter's doc), and synthesizes `nextPage`
    /// only when the page came back full. `prevPage` is always nil.
    ///
    /// **Why synthesis, not a native cursor:** unlike `listNotificationsNeutralPiefed`'s
    /// `getReplies`/`getMentions` (whose `PiefedRepliesResponse` carries a real `next_page` string
    /// cursor), PieFed's private-message list response (`PiefedPrivateMessageListResponse`,
    /// matching the spec's `ListPrivateMessagesResponse`) carries no cursor of any kind at all --
    /// just the bare `private_messages` array. This mirrors `getPrivateMessagesNeutralV3`'s exact
    /// emulation for the same reason.
    func getPrivateMessagesNeutralPiefed(
        unreadOnly: Bool,
        pageCursor: Cursor?
    ) async throws -> Page<PrivateMessageListItem> {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "getPrivateMessages") }

        let page = pageCursor.flatMap { Int($0.rawValue) } ?? 1

        let response = try await piefedClient.getPrivateMessages(
            unreadOnly: unreadOnly,
            page: page,
            limit: privateMessagesNeutralPiefedPageSize
        )

        let items = response.private_messages.map { neutralPrivateMessageListItem(fromPiefed: $0) }

        let nextPage = items.count == privateMessagesNeutralPiefedPageSize
            ? Cursor(rawValue: "\(page + 1)")
            : nil

        return Page(items: items, nextPage: nextPage, prevPage: nil)
    }
}
