//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension Components.Schemas.SortType {
    /// The post sort options, in the order to present them to the user.
    static let allCases: [Components.Schemas.SortType] = [
        .Active,
        .Hot,
        .New,
        .Old,
        .TopSixHour,
        .TopTwelveHour,
        .TopDay,
        .TopWeek,
        .TopMonth,
        .TopYear,
        .TopAll,
        .MostComments,
        .NewComments,
        .TopThreeMonths,
        .TopSixMonths,
        .TopNineMonths,
        .Controversial,
        .Scaled,
    ]

    private func trigger_compiler_error_when_new_cases_added() {
        let value = Components.Schemas.SortType.allCases.first!
        switch value {
        case .Active, .Hot, .New, .Old, .TopSixHour, .TopTwelveHour, .TopDay, .TopWeek,
             .TopMonth, .TopYear, .TopAll, .MostComments, .NewComments, .TopThreeMonths,
             .TopSixMonths, .TopNineMonths, .Controversial, .Scaled:
            break
        }
    }
}
