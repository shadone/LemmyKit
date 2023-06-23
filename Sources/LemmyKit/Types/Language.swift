//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/db_schema/src/source/language.rs

/// A language.
public struct Language: Decodable {
    public let id: LanguageId

    /// Language code.
    ///
    /// Two letter ISO639-1 language code. E.g. `sv`.
    ///
    /// Or an additional value `und` for Undefined language.
    public let code: String

    /// Language name. E.g.`Svenska`.
    public let name: String
}
