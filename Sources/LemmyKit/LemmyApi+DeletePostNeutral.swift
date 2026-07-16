//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Deletes or restores a post owned by the signed-in account and returns the
    /// version-neutral ``PostView`` reflecting the new deleted state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``votePostNeutral(id:direction:)`` shape: both backends'
    /// `DeletePost` request shapes agree (`post_id`, `deleted`), so only the id narrowing and the
    /// mapping direction differ. Both extract the returned `post_view` and map it via
    /// `neutralPostView(fromV3:)`/`neutralPostView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the post to delete or restore.
    ///   - deleted: true to delete the post, false to restore it.
    /// - Returns: the neutral `PostView` reflecting the new deleted state.
    /// - Note: requires authentication.
    func deletePostNeutral(id: Int64, deleted: Bool) async throws -> PostView {
        switch apiVersion {
        case .v3:
            try await deletePostNeutralV3(id: id, deleted: deleted)
        case .v4:
            try await deletePostNeutralV4(id: id, deleted: deleted)
        case .piefed:
            try await deletePostNeutralPiefed(id: id, deleted: deleted)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``deletePost(postID:deleted:)``, then maps the extracted v3 `post_view` up to the neutral
    /// shape.
    func deletePostNeutralV3(id: Int64, deleted: Bool) async throws -> PostView {
        let postID = try v3PostID(id)

        let response: Operations.deletePost.Output
        do {
            response = try await client.deletePost(body: .json(.init(
                post_id: postID,
                deleted: deleted
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPostView(fromV3: json.post_view)
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

    /// v4 path: calls the v4 generated client's `DeletePost` operation, then maps the extracted
    /// v4 `post_view` near-directly to the neutral shape. v4's `DeletePost` only documents the
    /// `ok` response for this operation (no `unauthorized`/`badRequest` cases like v3), so
    /// anything else falls through to `.undocumented`.
    func deletePostNeutralV4(id: Int64, deleted: Bool) async throws -> PostView {
        let response: LemmyKitV4Generated.Operations.DeletePost.Output
        do {
            response = try await v4Client.DeletePost(body: .json(.init(
                deleted: deleted,
                post_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return neutralPostView(fromV4: json.post_view)
            }

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.deletePost(postId:deleted:)` -- PieFed soft-deletes
    /// (tombstones) rather than purging, same as v3/v4 -- then maps the extracted `post_view` up
    /// to the neutral shape via `neutralPostView(fromPiefed:)`.
    func deletePostNeutralPiefed(id: Int64, deleted: Bool) async throws -> PostView {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "deletePost") }
        let response = try await piefedClient.deletePost(postId: id, deleted: deleted)
        return neutralPostView(fromPiefed: response.post_view)
    }
}
