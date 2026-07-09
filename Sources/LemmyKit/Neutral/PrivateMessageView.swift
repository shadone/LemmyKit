//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A private message paired with its sender and recipient, decoupled from the generated OpenAPI
/// schema.
///
/// Mirrors v4's `PrivateMessageView` — v3's `PrivateMessageView` has the identical three-field
/// shape, so both adapter directions (`PrivateMessageViewV3Mapping.swift`/
/// `PrivateMessageViewV4Mapping.swift`) are a direct field-for-field map, no emulation gaps.
public struct PrivateMessageView: Sendable, Equatable {
    /// The message itself.
    public var privateMessage: PrivateMessage

    /// The message's sender.
    public var creator: Person

    /// The message's recipient.
    public var recipient: Person

    public init(privateMessage: PrivateMessage, creator: Person, recipient: Person) {
        self.privateMessage = privateMessage
        self.creator = creator
        self.recipient = recipient
    }
}
