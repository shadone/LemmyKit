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

        // Lemmy 0.19.0 format: 2024-06-09T11:54:37.981990Z
        let parseStrategyWithNanosecAndZ = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(6))Z",
            locale: Locale(identifier: "C"),
            timeZone: utc
        )

        if let date = try? Date(stringValue, strategy: parseStrategyWithNanosecAndZ) {
            self = date
            return
        }

        // Lemmy 0.18 format: 2023-06-17T09:22:01.168808
        let parseStrategyWithNanosec = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(6))",
            locale: Locale(identifier: "C"),
            timeZone: utc
        )

        if let date = try? Date(stringValue, strategy: parseStrategyWithNanosec) {
            self = date
            return
        }

        // old Lemmy format
        let parseStrategyWithoutNanosec = Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits))",
            locale: Locale(identifier: "C"),
            timeZone: utc
        )

        self = try Date(stringValue, strategy: parseStrategyWithoutNanosec)
    }
}
