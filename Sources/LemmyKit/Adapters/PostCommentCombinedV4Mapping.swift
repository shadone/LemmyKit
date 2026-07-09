//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

/// A v4 `PostCommentCombinedView` decoded with neither its post nor its comment branch present.
///
/// The OpenAPI spec models `PostCommentCombinedView` as an `anyOf` of two `allOf` branches, each
/// requiring its own literal `type_` ("post" or "comment") alongside the full `PostView`/
/// `CommentView` payload. swift-openapi-generator represents an `anyOf` like this as two
/// independent optional payloads on the same struct (`value1` for the post branch, `value2` for
/// the comment branch) and guarantees at least one decodes successfully -- decoding fails
/// outright otherwise (see `Swift.DecodingError.verifyAtLeastOneSchemaIsNotNil` in the generated
/// `init(from:)`). Seeing neither payload set here would mean that generator invariant was
/// violated, which should never happen in practice.
enum PostCommentCombinedViewError: Error, Equatable {
    case neitherBranchPresent
}

/// Maps a v4 `Components.Schemas.PostCommentCombinedView` to the neutral `PostOrComment`,
/// switching on which of the generator's two `anyOf` payloads decoded (see
/// `PostCommentCombinedViewError`'s doc for why the generator shapes it this way). The post
/// branch (`value1`) is checked first only because it's listed first in the spec's `anyOf`; in
/// practice the two are mutually exclusive, since each requires a different literal `type_`.
///
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``PostCommentCombinedViewError/neitherBranchPresent``
///   if somehow neither payload decoded (see that error's doc -- not expected in practice).
func neutralPostOrComment(
    fromV4 v4: LemmyKitV4Generated.Components.Schemas.PostCommentCombinedView
) throws -> PostOrComment {
    if let post = v4.value1 {
        return .post(neutralPostView(fromV4: post.value2))
    }
    if let comment = v4.value2 {
        return .comment(neutralCommentView(fromV4: comment.value2))
    }
    throw LemmyApiError.unknown(PostCommentCombinedViewError.neitherBranchPresent)
}
