//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// An opaque pagination cursor.
///
/// Consumers pass a `Cursor` back to a subsequent listing call to continue paging, but must
/// never parse its `rawValue` or construct one from anything other than a cursor a backend
/// handed back. v4 backends hand back the server's own opaque cursor string directly. v3
/// backends have no native cursor concept, so the V3 adapter synthesizes one internally
/// (typically encoding a page/limit offset) — its encoding is an implementation detail that
/// may change and must not be relied upon.
public struct Cursor: Sendable, Equatable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
