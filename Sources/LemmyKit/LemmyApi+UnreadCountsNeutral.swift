//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches the signed-in account's unread-notification summary and returns the
    /// version-neutral ``UnreadCounts``.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``): v4's `GetUnreadCounts`, or v3's existing `getUnreadCount()` wrapper. See
    /// ``UnreadCounts``'s doc for how the two backends' incompatible shapes are reconciled.
    ///
    /// - Returns: the neutral `UnreadCounts`.
    /// - Note: requires authentication.
    func unreadCountsNeutral() async throws -> UnreadCounts {
        switch apiVersion {
        case .v3:
            try await unreadCountsNeutralV3()
        case .v4:
            try await unreadCountsNeutralV4()
        case .piefed:
            try await unreadCountsNeutralPiefed()
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the existing `getUnreadCount()` wrapper, then sums its three per-kind
    /// counts into ``UnreadCounts/total`` while also preserving each count individually.
    func unreadCountsNeutralV3() async throws -> UnreadCounts {
        let response = try await getUnreadCount()
        return UnreadCounts(
            total: response.replies + response.mentions + response.private_messages,
            replies: response.replies,
            mentions: response.mentions,
            privateMessages: response.private_messages
        )
    }

    /// v4 path: calls the v4 generated client's `GetUnreadCounts` operation directly, mapping its
    /// single `notification_count` to ``UnreadCounts/total``; the per-kind fields are always nil
    /// here, since v4 doesn't break the count down by kind (see ``UnreadCounts``'s doc).
    /// `GetUnreadCounts` only documents the `ok` response, so anything else falls through to
    /// `.undocumented`.
    func unreadCountsNeutralV4() async throws -> UnreadCounts {
        let response: LemmyKitV4Generated.Operations.GetUnreadCounts.Output
        do {
            response = try await v4Client.GetUnreadCounts()
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return UnreadCounts(
                    total: json.notification_count,
                    replies: nil,
                    mentions: nil,
                    privateMessages: nil
                )
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.unreadCount()`, then maps the extracted response to the
    /// neutral shape via `neutralUnreadCounts(fromPiefed:)`, which additionally folds PieFed's
    /// `other` extra (activity alerts, reports, ...) into ``UnreadCounts/total`` -- see that
    /// adapter's doc.
    func unreadCountsNeutralPiefed() async throws -> UnreadCounts {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "unreadCounts") }
        let response = try await piefedClient.unreadCount()
        return neutralUnreadCounts(fromPiefed: response)
    }
}
