//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A wrapper around URL for parsing not strict standard compliant links.
///
/// This type could be used in ``Decodable`` models for safer parsing of URLs. Swift ``URL`` is very strict
/// about the url strings it parses. Not everything that is permitted in a browser url bar is permitted by ``URL``.
///
/// LenientUrl attempts to decode raw string into URL as leniently as possible but does not fail if it fails.
public struct LenientUrl: Decodable {
    /// The original raw string representation of the url.
    public let rawValue: String

    /// Contains URL if we managed to parse it from a raw string.
    public let url: URL?

    // MARK: Functions

    public init(stringValue: String) {
        self.rawValue = stringValue
        url = URL(lenientString: stringValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(String.self)
        url = URL(lenientString: rawValue)
    }
}
