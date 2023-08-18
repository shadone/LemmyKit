//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct CommentPath {
    let path: [CommentId]

    public var depth: Int {
        assert(!path.isEmpty)
        return path.count - 1
    }

    public var pathString: String {
        path
            .map { "\($0)" }
            .joined(separator: ".")
    }

    /// Return a comment that that is the parent of the commit represented by this path.
    ///
    /// For example for path `0.1234.5678.9876` the parent commit id is `5678`.
    public var parent: CommentId? {
        guard path.count > 2 else {
            // if only 2 elements that this is the root most comment, no parent
            // e.g. path: "0.1234"
            return nil
        }
        return path[path.count - 2]
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
