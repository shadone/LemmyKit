//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches the unified notification inbox and returns the version-neutral, cursor-paginated
    /// ``Page`` of ``NotificationView``, sorted newest first.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``): v4's single `GET /account/notification/list`, mapped near-directly via
    /// `neutralNotificationView(fromV4:)`; or, on v3 (which has no unified inbox endpoint at
    /// all), a fan-out across whichever of `getReplies`/`getPersonMentions`/`getPrivateMessages`
    /// the requested `kind` needs, followed by a merge-sort into one descending timeline (see
    /// `listNotificationsNeutralV3`'s doc for the simplifications that path makes).
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread notifications, false for all.
    ///   - pageCursor: opaque cursor from a previous page's `nextPage`/`prevPage`; nil fetches the
    ///     first page. Ignored on a v3 backend — see `listNotificationsNeutralV3`'s doc for why.
    ///   - kind: restricts the result to one ``NotificationKind``; nil returns every kind. On v4
    ///     this maps to `ListNotifications`'s `type_` filter, sent server-side. On v3 this
    ///     narrows which of the three fan-out endpoints are called at all — see
    ///     `listNotificationsNeutralV3`'s doc for the per-kind mapping, including the two kinds
    ///     with no v3 source.
    /// - Returns: a `Page` of the neutral `NotificationView`s, newest first.
    func listNotificationsNeutral(
        unreadOnly: Bool = false,
        pageCursor: Cursor? = nil,
        kind: NotificationKind? = nil
    ) async throws -> Page<NotificationView> {
        switch apiVersion {
        case .v3:
            try await listNotificationsNeutralV3(unreadOnly: unreadOnly, kind: kind)
        case .v4:
            try await listNotificationsNeutralV4(unreadOnly: unreadOnly, pageCursor: pageCursor, kind: kind)
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "listNotifications")
        }
    }
}

private extension LemmyApi {
    /// v4 path: calls the v4 generated client's `ListNotifications` operation directly, sending
    /// `kind` mapped to the `type_` query filter (nil omits the filter entirely, which the server
    /// treats as "all kinds" -- the same behavior as sending the filter's `all` literal), then
    /// maps the extracted items to the neutral shape. Like `getPostsNeutral`'s v4 path,
    /// `ListNotifications` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func listNotificationsNeutralV4(
        unreadOnly: Bool,
        pageCursor: Cursor?,
        kind: NotificationKind?
    ) async throws -> Page<NotificationView> {
        let response: LemmyKitV4Generated.Operations.ListNotifications.Output
        do {
            response = try await v4Client.ListNotifications(query: .init(
                page_cursor: pageCursor?.rawValue,
                unread_only: unreadOnly,
                type_: v4NotificationTypeFilter(for: kind)
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return try neutralPage(fromV4: json) { try neutralNotificationView(fromV4: $0) }
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v3 path: v3 has no unified notification-inbox endpoint, so this fans out to whichever of
    /// the three separate endpoints `kind` requires, concurrently, maps each response's items to
    /// the neutral `NotificationView`
    /// (`neutralNotificationView(fromV3Reply:/fromV3Mention:/fromV3PrivateMessage:)`),
    /// concatenates, and sorts the merged list by `notification.publishedAt` descending — a
    /// k-way merge by timestamp rather than a true unified listing.
    ///
    /// `kind`'s effect on which endpoints are called:
    /// - `nil`: all three endpoints (the original unfiltered fan-out).
    /// - `.reply`: only `getReplies`.
    /// - `.mention`: only `getPersonMentions`.
    /// - `.privateMessage`: only `getPrivateMessages`.
    /// - `.subscribed`, `.modAction`: no v3 source exists for either (see ``NotificationKind``'s
    ///   doc), so no endpoint is called and this returns an empty page rather than throwing.
    ///
    /// Two deliberate simplifications, both out of scope for this pass (see the Phase 5 design
    /// doc's "Notifications" section):
    /// - **Single page only.** `pageCursor` is ignored and the returned `Page` always has
    ///   `nextPage`/`prevPage` nil. Each of the three v3 sources paginates independently via its
    ///   own page/limit; correctly merging three independent cursors into one coherent cursor
    ///   over the merged timeline is nontrivial (a page boundary in the merge doesn't line up
    ///   with a page boundary in any one source) and is left to a future refinement.
    /// - **All-or-nothing.** If any of the called endpoints throws, the whole call throws and no
    ///   partial results are returned. A partial-fan-out/partial-failure UX (for example, still
    ///   showing replies if only private messages failed to load) is a future concern, not this
    ///   pass's — simplest-thing-that-works over graceful degradation, for a first cut.
    ///
    /// When more than one endpoint is called, they run concurrently via `async let`, since
    /// they're independent network round-trips — running them concurrently instead of
    /// sequentially meaningfully cuts latency, even though `LemmyApi` is an actor (concurrent
    /// callers still interleave at each call's network-await suspension point rather than truly
    /// running in parallel).
    func listNotificationsNeutralV3(
        unreadOnly: Bool,
        kind: NotificationKind?
    ) async throws -> Page<NotificationView> {
        let merged: [NotificationView]
        switch kind {
        case .subscribed, .modAction:
            merged = []

        case .reply:
            let replies = try await getReplies(unreadOnly: unreadOnly)
            merged = replies.replies.map { neutralNotificationView(fromV3Reply: $0) }

        case .mention:
            let mentions = try await getPersonMentions(unreadOnly: unreadOnly)
            merged = mentions.mentions.map { neutralNotificationView(fromV3Mention: $0) }

        case .privateMessage:
            let privateMessages = try await getPrivateMessages(unreadOnly: unreadOnly)
            merged = privateMessages.private_messages.map { neutralNotificationView(fromV3PrivateMessage: $0) }

        case nil:
            async let repliesResponse = getReplies(unreadOnly: unreadOnly)
            async let mentionsResponse = getPersonMentions(unreadOnly: unreadOnly)
            async let privateMessagesResponse = getPrivateMessages(unreadOnly: unreadOnly)

            let (replies, mentions, privateMessages) = try await (
                repliesResponse,
                mentionsResponse,
                privateMessagesResponse
            )

            merged = replies.replies.map { neutralNotificationView(fromV3Reply: $0) }
                + mentions.mentions.map { neutralNotificationView(fromV3Mention: $0) }
                + privateMessages.private_messages.map { neutralNotificationView(fromV3PrivateMessage: $0) }
        }

        // v3-sourced notifications always carry a real `publishedAt` (each of the three v3
        // sources has a required, non-optional `published` date) -- `.distantPast` is a
        // defensive fallback for the neutral field's `Date?` type, not something expected to
        // trigger in practice.
        let sorted = merged.sorted {
            ($0.notification.publishedAt ?? .distantPast) > ($1.notification.publishedAt ?? .distantPast)
        }

        return Page(items: sorted, nextPage: nil, prevPage: nil)
    }
}

/// Maps a neutral ``NotificationKind`` to v4's `NotificationTypeFilter`, a straight case-for-case
/// rename via `NotificationType`; nil (no filter) leaves the request's `type_` unset, which the
/// server treats the same as sending the filter's `all` literal.
private func v4NotificationTypeFilter(
    for kind: NotificationKind?
) -> LemmyKitV4Generated.Components.Schemas.NotificationTypeFilter? {
    guard let kind else { return nil }

    let type: LemmyKitV4Generated.Components.Schemas.NotificationType = switch kind {
    case .mention: .mention
    case .reply: .reply
    case .subscribed: .subscribed
    case .privateMessage: .private_message
    case .modAction: .mod_action
    }
    return .init(value1: type)
}
