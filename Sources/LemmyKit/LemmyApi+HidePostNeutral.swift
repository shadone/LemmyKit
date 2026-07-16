//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Hides or unhides a post for the signed-in account.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``). The two backends disagree on shape in both directions: v3's `HidePost`
    /// request carries an *array* of post ids (`post_ids`), even though this call only ever hides
    /// one, so the v3 path wraps `id` in a single-element array; v4's `HidePost` request instead
    /// takes a single scalar `post_id`. On the response side v3's `hidePost` returns a bare
    /// `SuccessResponse`, while v4's `HidePost` returns a full `PostResponse` -- since this method
    /// reports success by not throwing (there's no single post view shape both backends could
    /// hand back), either response body is discarded once the `.ok` case is confirmed.
    ///
    /// - Parameters:
    ///   - id: the post to hide or unhide.
    ///   - hidden: true to hide the post, false to unhide it.
    /// - Note: requires authentication.
    func hidePostNeutral(id: Int64, hidden: Bool) async throws {
        switch apiVersion {
        case .v3:
            try await hidePostNeutralV3(id: id, hidden: hidden)
        case .v4:
            try await hidePostNeutralV4(id: id, hidden: hidden)
        case .piefed:
            try await hidePostNeutralPiefed(id: id, hidden: hidden)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``hidePost(postIDs:hide:)``, wrapping the single `id` in the array v3's `HidePost` request
    /// requires.
    func hidePostNeutralV3(id: Int64, hidden: Bool) async throws {
        let postID = try v3PostID(id)

        let response: Operations.hidePost.Output
        do {
            response = try await client.hidePost(body: .json(.init(
                post_ids: [postID],
                hide: hidden
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

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

    /// v4 path: calls the v4 generated client's `HidePost` operation with a scalar `post_id`.
    /// Unlike v3, v4's `HidePost` returns a `PostResponse` (not a `SuccessResponse`); its body is
    /// discarded here since this method reports success by not throwing. v4's `HidePost` only
    /// documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases like
    /// v3), so anything else falls through to `.undocumented`.
    func hidePostNeutralV4(id: Int64, hidden: Bool) async throws {
        let response: LemmyKitV4Generated.Operations.HidePost.Output
        do {
            response = try await v4Client.HidePost(body: .json(.init(
                hide: hidden,
                post_id: id
            )))
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case .ok:
            return

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }

    /// PieFed path: calls `PiefedClient.hidePost(postId:hide:)`, whose route returns a full
    /// `PiefedPostResponse` (not a bare success payload) -- like the v3/v4 paths, this method
    /// reports success by not throwing, so the returned `post_view` is discarded once the call
    /// returns without error.
    func hidePostNeutralPiefed(id: Int64, hidden: Bool) async throws {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "hidePost") }
        _ = try await piefedClient.hidePost(postId: id, hide: hidden)
    }
}
