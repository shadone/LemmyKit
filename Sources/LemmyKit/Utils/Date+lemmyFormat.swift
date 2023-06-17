//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

extension Date {
    init(lemmyFormat stringValue: String) throws {
        guard #available(macOS 12.0, *) else {
            fatalError()
        }

        let utc = TimeZone(abbreviation: "UTC")!

        let parseStrategyWithNanosec = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(6))",
            locale: Locale(identifier: "C"),
            timeZone: utc
        )

        if let date = try? Date(stringValue, strategy: parseStrategyWithNanosec) {
            self = date
            return
        }

        let parseStrategyWithoutNanosec = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits))",
            locale: Locale(identifier: "C"),
            timeZone: utc
        )

        self = try Date(stringValue, strategy: parseStrategyWithoutNanosec)
    }
}
