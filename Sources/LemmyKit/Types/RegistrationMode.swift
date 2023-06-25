//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/lib.rs

public enum RegistrationMode: String, Decodable {
    /// Closed to public.
    case closed = "Closed"

    /// Open, but pending approval of a registration application.
    case requireApplication = "RequireApplication"

    /// Open to all.
    case open = "Open"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        switch stringValue {
        case "Closed", "closed":
            self = .closed

        case "RequireApplication", "requireapplication":
            self = .requireApplication

        case "Open", "open":
            self = .open

        default:
            throw DecodingError.dataCorrupted(.init(
                codingPath: container.codingPath,
                debugDescription: "Cannot initialize RegistrationMode from invalid String value '\(stringValue)'"
            ))
        }
    }
}
