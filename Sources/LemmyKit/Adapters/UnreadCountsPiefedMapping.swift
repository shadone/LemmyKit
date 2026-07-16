//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds the neutral `UnreadCounts` for a PieFed `PiefedUnreadCountResponse`.
///
/// PieFed's `GET /api/alpha/user/unread_count` matches Lemmy v3's `getUnreadCount` shape exactly
/// (`mentions`/`replies`/`private_messages`) plus one PieFed-only extra, `other` (activity alerts,
/// reports, and any other unread notification with no dedicated neutral field). Mirrors
/// `LemmyApi+UnreadCountsNeutral.swift`'s v3 path (`unreadCountsNeutralV3`), which sums its three
/// per-kind counts into `total` while also preserving each individually -- this does the same, but
/// additionally folds `other` into `total` (there being no neutral field of its own for it), since
/// omitting it from the total would undercount PieFed's actual unread total.
package func neutralUnreadCounts(fromPiefed response: PiefedUnreadCountResponse) -> UnreadCounts {
    UnreadCounts(
        total: Int64(response.mentions) + Int64(response.replies) + Int64(response.private_messages) + Int64(response.other),
        replies: Int64(response.replies),
        mentions: Int64(response.mentions),
        privateMessages: Int64(response.private_messages)
    )
}
