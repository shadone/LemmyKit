//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

extension Components.Schemas.SortType: Identifiable {
    /// The raw value string, used as a stable identity (e.g. in SwiftUI lists).
    public var id: String { rawValue }
}
