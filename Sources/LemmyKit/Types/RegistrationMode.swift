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
}
