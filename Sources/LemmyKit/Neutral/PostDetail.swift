//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// A single post together with the other posts cross-posting the same link.
///
/// Returned by ``LemmyApi/getPostNeutral(id:)``. Both backends' `GetPost` response carry a
/// `cross_posts` list -- other posts (in other communities, or at other times) linking the same
/// url -- alongside the requested `post_view`; this pairs them so a caller can render "also posted
/// in ..." without a second request.
public struct PostDetail: Sendable, Equatable {
    /// The requested post.
    public let post: PostView

    /// Other posts cross-posting the same link, newest first as the server orders them; empty when
    /// the post has no cross-posts (or is a text post with no url to cross-post).
    public let crossPosts: [PostView]

    /// Creates a post detail from a post and its cross-posts.
    ///
    /// - Parameters:
    ///   - post: the requested post.
    ///   - crossPosts: other posts cross-posting the same link; empty for none.
    public init(post: PostView, crossPosts: [PostView]) {
        self.post = post
        self.crossPosts = crossPosts
    }
}
