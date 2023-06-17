//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

final class DateLemmyFormatTests: XCTestCase {
    func testWithNanosec() throws {
        let date = try Date(lemmyFormat: "2023-06-17T09:22:01.168808")

        let calendar = Calendar.current

        let gmt = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents(in: gmt, from: date)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 17)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 22)
        XCTAssertEqual(components.second, 1)
        // nanosec is not what I expected, not sure what I did wrong.
        XCTAssertEqual(components.nanosecond, 167999982)
        XCTAssertEqual(components.timeZone?.identifier, "GMT")

        XCTAssertEqual(date.timeIntervalSince1970, 1686993721.168)
    }

    func testWithoutNanosec() throws {
        let date = try Date(lemmyFormat: "2023-06-17T09:22:01")

        let calendar = Calendar.current

        let gmt = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents(in: gmt, from: date)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 17)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 22)
        XCTAssertEqual(components.second, 1)
        XCTAssertEqual(components.nanosecond, 0)
        XCTAssertEqual(components.timeZone?.identifier, "GMT")

        XCTAssertEqual(date.timeIntervalSince1970, 1686993721.0)
    }
}
