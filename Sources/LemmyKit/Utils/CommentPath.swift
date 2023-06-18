//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CommentPath {
    let path: [CommentId]

    public var depth: Int {
        assert(path.count > 0)
        return path.count - 1
    }

    public var pathString: String {
        path
            .map { "\($0)" }
            .joined(separator: ".")
    }

    public static let root: CommentPath = .init(path: [0])

    // MARK: Functions

    init(path: [CommentId]) {
        self.path = path
    }

    public init(path: String) {
        self.path = path
            .split(separator: ".")
            .compactMap {
                guard let commentId = CommentId($0) else {
                    assertionFailure("Got invalid comment path '\(path)'")
                    return nil
                }
                return commentId
            }
    }

    public func appending(_ commentId: CommentId) -> CommentPath {
        CommentPath(path: path + [commentId])
    }
}
