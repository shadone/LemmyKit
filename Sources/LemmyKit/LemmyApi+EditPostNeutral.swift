//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Edits an existing post and returns the version-neutral ``PostView`` reflecting the change.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``votePostNeutral(id:direction:)`` shape. Only the fields
    /// you pass are changed; omitted parameters leave the existing values intact. Both backends
    /// extract the returned `post_view` and map it via
    /// `neutralPostView(fromV3:)`/`neutralPostView(fromV4:)`.
    ///
    /// Only the fields Spud plausibly needs to edit are exposed here (name, url, body, nsfw);
    /// v3/v4's other `EditPost` fields (`alt_text`, `language_id`, `custom_thumbnail`, v4-only
    /// `tags`/`scheduled_publish_time_at`) are omitted as YAGNI and always sent as nil, leaving
    /// them unchanged.
    ///
    /// - Parameters:
    ///   - id: the post to edit.
    ///   - name: new post title; nil leaves the existing title unchanged.
    ///   - url: new link url; nil leaves the existing url unchanged.
    ///   - body: new markdown body; nil leaves the existing body unchanged.
    ///   - nsfw: true to mark the post NSFW, false to clear the flag; nil leaves it unchanged.
    /// - Returns: the neutral `PostView` reflecting the edit.
    /// - Note: requires authentication.
    func editPostNeutral(
        id: Int64,
        name: String?,
        url: String?,
        body: String?,
        nsfw: Bool? = nil
    ) async throws -> PostView {
        switch apiVersion {
        case .v3:
            try await editPostNeutralV3(id: id, name: name, url: url, body: body, nsfw: nsfw)
        case .v4:
            try await editPostNeutralV4(id: id, name: name, url: url, body: body, nsfw: nsfw)
        case .piefed:
            try await editPostNeutralPiefed(id: id, name: name, url: url, body: body, nsfw: nsfw)
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``editPost(postID:name:url:body:altText:nsfw:languageID:customThumbnail:)``, then maps the
    /// extracted v3 `post_view` up to the neutral shape.
    func editPostNeutralV3(
        id: Int64,
        name: String?,
        url: String?,
        body: String?,
        nsfw: Bool?
    ) async throws -> PostView {
        let postID = try v3PostID(id)

        let response: Operations.editPost.Output
        do {
            response = try await client.editPost(body: .json(.init(
                post_id: postID,
                name: name,
                url: url,
                body: body,
                nsfw: nsfw
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

    /// v4 path: calls the v4 generated client's `EditPost` operation, then maps the extracted v4
    /// `post_view` near-directly to the neutral shape. v4's `EditPost` only documents the `ok`
    /// response for this operation (no `unauthorized`/`badRequest` cases like v3), so anything
    /// else falls through to `.undocumented`.
    func editPostNeutralV4(
        id: Int64,
        name: String?,
        url: String?,
        body: String?,
        nsfw: Bool?
    ) async throws -> PostView {
        let response: LemmyKitV4Generated.Operations.EditPost.Output
        do {
            response = try await v4Client.EditPost(body: .json(.init(
                nsfw: nsfw,
                body: body,
                url: url,
                name: name,
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

    /// PieFed path: calls `PiefedClient.editPost(postId:title:body:url:nsfw:)`, passing `name`
    /// through as PieFed's `title` wire field (same rename as
    /// ``createPostNeutralPiefed(name:communityId:url:body:nsfw:languageId:)``). Only `id` is
    /// required on the wire; every other parameter left `nil` here is simply omitted from the
    /// request body (the client's request struct relies on `Encodable`'s `encodeIfPresent`, so a
    /// `nil` optional is never sent as JSON `null`) -- PieFed keeps the existing value for any
    /// field the request omits, matching the neutral contract that a `nil` parameter leaves that
    /// field unchanged. Then maps the extracted `post_view` up to the neutral shape via
    /// `neutralPostView(fromPiefed:)`.
    func editPostNeutralPiefed(
        id: Int64,
        name: String?,
        url: String?,
        body: String?,
        nsfw: Bool?
    ) async throws -> PostView {
        guard let piefedClient else { throw LemmyApiError.unsupportedByDialect(operation: "editPost") }
        let response = try await piefedClient.editPost(postId: id, title: name, body: body, url: url, nsfw: nsfw)
        return neutralPostView(fromPiefed: response.post_view)
    }
}
