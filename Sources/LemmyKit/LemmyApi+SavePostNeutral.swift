//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Saves or unsaves a post for the signed-in account and returns the version-neutral
    /// ``PostView`` reflecting the new saved state.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``getPostNeutral(id:)`` shape: the v3 client's `savePost`
    /// mapped "up" via `neutralPostView(fromV3:)`, or the v4 client's `SavePost` mapped
    /// near-directly via `neutralPostView(fromV4:)`.
    ///
    /// - Parameters:
    ///   - id: the post to save or unsave.
    ///   - saved: true to save the post, false to unsave it.
    /// - Returns: the neutral `PostView` reflecting the new saved state.
    /// - Note: requires authentication.
    func savePostNeutral(id: Int64, saved: Bool) async throws -> PostView {
        switch apiVersion {
        case .v3:
            try await savePostNeutralV3(id: id, saved: saved)
        case .v4:
            try await savePostNeutralV4(id: id, saved: saved)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``savePost(postID:save:)``, then maps the extracted v3 `post_view` up to the neutral
    /// shape.
    func savePostNeutralV3(id: Int64, saved: Bool) async throws -> PostView {
        let postID = try v3PostID(id)

        let response: Operations.savePost.Output
        do {
            response = try await client.savePost(body: .json(.init(
                post_id: postID,
                save: saved
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

    /// v4 path: calls the v4 generated client's `SavePost` operation, then maps the extracted v4
    /// `post_view` near-directly to the neutral shape. v4's `SavePost` only documents the `ok`
    /// response for this operation (no `unauthorized`/`badRequest` cases like v3), so anything
    /// else falls through to `.undocumented`.
    func savePostNeutralV4(id: Int64, saved: Bool) async throws -> PostView {
        let response: LemmyKitV4Generated.Operations.SavePost.Output
        do {
            response = try await v4Client.SavePost(body: .json(.init(
                save: saved,
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
}
