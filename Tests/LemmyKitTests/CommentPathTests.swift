//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

final class CommentPathTests: XCTestCase {
    func testFromString() throws {
        XCTAssertEqual(
            CommentPath(path: "0.42").pathString,
            "0.42"
        )

        XCTAssertEqual(
            CommentPath(path: "0.1.2.3").pathString,
            "0.1.2.3"
        )
    }

    func testDepth() throws {
        XCTAssertEqual(
            CommentPath(path: "0.42").depth,
            1
        )

        XCTAssertEqual(
            CommentPath(path: "0.1.2.3").depth,
            3
        )

        XCTAssertEqual(
            CommentPath(path: "0.222327.224221.224614.224774.225629.230507.232432.239427").depth,
            8
        )
    }

    func testRoot() throws {
        XCTAssertEqual(CommentPath.root.depth, 0)
        XCTAssertEqual(CommentPath.root.pathString, "0")
    }
}
