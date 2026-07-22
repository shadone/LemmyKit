//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A Lemmy comment's materialized path: the chain of ancestor comment ids
/// from the synthetic root down to the comment itself.
///
/// Lemmy stores comment nesting as a dotted path string such as `0.1234.5678`,
/// where `0` is the synthetic root and each later element is a comment id.
/// `CommentPath` parses and navigates that representation.
public struct CommentPath: Sendable {
    let path: [Components.Schemas.CommentID]

    /// How deeply the comment is nested, counting the synthetic root as depth
    /// `0`. A top-level comment (path `0.<id>`) therefore has depth `1`, and
    /// each additional path segment adds one.
    public var depth: Int {
        assert(!path.isEmpty)
        return path.count - 1
    }

    /// The dotted path string, e.g. `0.1234.5678`.
    public var pathString: String {
        path
            .map { "\($0)" }
            .joined(separator: ".")
    }

    /// The id of this comment's parent, or `nil` if it is a top-level comment.
    ///
    /// For example, for path `0.1234.5678.9876` the parent comment id is `5678`.
    public var parent: Components.Schemas.CommentID? {
        guard path.count > 2 else {
            // if only 2 elements that this is the root most comment, no parent
            // e.g. path: "0.1234"
            return nil
        }
        return path[path.count - 2]
    }

    /// The synthetic root path (`0`) that every top-level comment descends from.
    public static let root: CommentPath = .init(path: [0])

    // MARK: Functions

    init(path: [Components.Schemas.CommentID]) {
        self.path = path
    }

    /// Creates a path by parsing a dotted path string such as `0.1234.5678`.
    /// - Parameter path: the dotted comment-path string to parse.
    public init(path: String) {
        self.path = path
            .split(separator: ".")
            .compactMap {
                guard let commentId = Components.Schemas.CommentID($0) else {
                    assertionFailure("Got invalid comment path '\(path)'")
                    return nil
                }
                return commentId
            }
    }

    /// Returns a new path with `commentId` appended as the deepest element.
    /// - Parameter commentId: the child comment id to append.
    public func appending(_ commentId: Components.Schemas.CommentID) -> CommentPath {
        CommentPath(path: path + [commentId])
    }
}
