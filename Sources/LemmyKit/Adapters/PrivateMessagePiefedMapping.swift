//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Maps a PieFed `PiefedPrivateMessageView` to the neutral `PrivateMessageView` -- the "emulate
/// upward" adapter direction, the same pattern as `PrivateMessageViewV3Mapping.swift`.
///
/// PieFed's `PiefedPrivateMessage.read` is dropped here, not carried onto the neutral
/// `PrivateMessage` -- see that type's doc for why (it feeds a listing item's `isRead` instead, at
/// the call site in `neutralPrivateMessageListItem(fromPiefed:)` below -- the same split
/// `PrivateMessageViewV3Mapping.swift`/`PrivateMessageNotificationV3Mapping.swift` use).
/// `deletedByRecipient`/`removed` have no PieFed source and default to `false`, the same "no v3
/// source" pattern `PrivateMessageViewV3Mapping.swift` uses for the identical v4-only fields.
///
/// `deleted`/`local` are `Optional` on `PiefedPrivateMessage` purely for decode-safety (kept "not
/// read by any neutral adapter" other than this fallback); every captured PieFed response populates
/// both, so this only falls back to `false` if a future PieFed drop of one of these keys is ever
/// actually observed, matching the Phase-1 "no signal -> false" boolean convention. `ap_id` is
/// required on `PiefedPrivateMessage` (matching the spec and every sibling PieFed entity), so it's
/// read straight through with no fallback.
package func neutralPrivateMessageView(fromPiefed view: PiefedPrivateMessageView) -> PrivateMessageView {
    PrivateMessageView(
        privateMessage: PrivateMessage(
            id: view.private_message.id,
            creatorId: view.private_message.creator_id,
            recipientId: view.private_message.recipient_id,
            content: view.private_message.content,
            deleted: view.private_message.deleted ?? false,
            deletedByRecipient: false,
            removed: false,
            local: view.private_message.local ?? false,
            apId: view.private_message.ap_id,
            publishedAt: piefedDate(view.private_message.published) ?? Date(timeIntervalSince1970: 0),
            updatedAt: nil
        ),
        creator: neutralPerson(fromPiefed: view.creator),
        recipient: neutralPerson(fromPiefed: view.recipient)
    )
}

/// Pairs a PieFed `PiefedPrivateMessageView` with its read state, as the neutral
/// `PrivateMessageListItem`.
///
/// The neutral `PrivateMessageView`/`PrivateMessage` carry no read field at all (see
/// `PrivateMessage.swift`'s doc), so a listing item must pair the mapped view with `isRead`
/// explicitly -- sourced here from PieFed's `private_message.read`, mirroring
/// `PrivateMessageNotificationV3Mapping.swift`'s equivalent pairing at its own call site.
package func neutralPrivateMessageListItem(fromPiefed view: PiefedPrivateMessageView) -> PrivateMessageListItem {
    PrivateMessageListItem(
        view: neutralPrivateMessageView(fromPiefed: view),
        isRead: view.private_message.read
    )
}
