//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension Components.Schemas.CommentSortType {
    /// The comment sort options, in the order to present them to the user.
    static let allCases: [Components.Schemas.CommentSortType] = [
        .Hot,
        .Top,
        .New,
        .Old,
        .Controversial,
    ]

    private func trigger_compiler_error_when_new_cases_added() {
        let value = Components.Schemas.CommentSortType.allCases.first!
        switch value {
        case .Hot, .Top, .New, .Old, .Controversial:
            break
        }
    }
}
