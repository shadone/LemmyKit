//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Fetches a post by its id and returns the version-neutral ``PostDetail`` -- the post plus its
    /// cross-posts.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``): the v3 client's `getPost` mapped "up" via `neutralPostView(fromV3:)`, or
    /// the v4 client's `GetPost` mapped near-directly via `neutralPostView(fromV4:)`. Both backends'
    /// `GetPost` response carry a `cross_posts` list (other posts linking the same url) alongside
    /// the requested `post_view`; both are mapped through the same `PostView` adapter, so a
    /// v3-backed and a v4-backed detail read identically. This is the first endpoint wired through
    /// the neutral surface end-to-end -- facade dispatch, generated client call, neutral mapping --
    /// the shape the rest of the endpoints follow.
    ///
    /// Named `getPostNeutral` (rather than `getPost`) to avoid clashing with the existing
    /// v3-only ``getPost(id:)``; a later step retargets/renames once every caller has moved onto
    /// the neutral surface.
    ///
    /// - Parameter id: the post to fetch.
    /// - Returns: the neutral `PostDetail` for the requested post, with its cross-posts (empty when
    ///   there are none).
    func getPostNeutral(id: Int64) async throws -> PostDetail {
        switch apiVersion {
        case .v3:
            try await getPostNeutralV3(id: id)
        case .v4:
            try await getPostNeutralV4(id: id)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``getPost(id:)``, then maps the extracted v3 `post_view` and its `cross_posts` up to the
    /// neutral shape.
    func getPostNeutralV3(id: Int64) async throws -> PostDetail {
        let response: Operations.getPost.Output
        do {
            response = try await client.getPost(.init(query: .init(
                id: v3PostID(id)
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return PostDetail(
                    post: neutralPostView(fromV3: json.post_view),
                    crossPosts: json.cross_posts.map { neutralPostView(fromV3: $0) }
                )
            }

        case let .unauthorized(response):
            switch response.body {
            case let .json(json):
                switch json.error {
                case .incorrect_login:
                    throw LemmyApiError.unauthorized(message: json.message)
                }
            }

        case let .badRequest(response):
            switch response.body {
            case let .json(json):
                throw LemmyApiError.serverError(json)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// v4 path: calls the v4 generated client's `GetPost` operation, then maps the extracted v4
    /// `post_view` and its `cross_posts` near-directly to the neutral shape. v4's `GetPost` only
    /// documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases like
    /// v3), so anything else falls through to `.undocumented`.
    func getPostNeutralV4(id: Int64) async throws -> PostDetail {
        let response: LemmyKitV4Generated.Operations.GetPost.Output
        do {
            response = try await v4Client.GetPost(query: .init(
                id: LemmyKitV4Generated.Components.Schemas.PostId(id)
            ))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return PostDetail(
                    post: neutralPostView(fromV4: json.post_view),
                    crossPosts: json.cross_posts.map { neutralPostView(fromV4: $0) }
                )
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}
