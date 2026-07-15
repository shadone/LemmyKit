//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated

public extension LemmyApi {
    /// Creates a new post and returns the version-neutral ``PostView`` for it.
    ///
    /// Dispatches to whichever generated backend this instance was configured with (see
    /// ``ApiVersion``), following the ``votePostNeutral(id:direction:)`` shape: the v3 client's
    /// `createPost` narrows `communityId`/`languageId` down to v3's `Int32`-backed ids, while the
    /// v4 client's `CreatePost` takes them as-is (v4's `LanguageId`/`CommunityId` are already
    /// `Int64`). Both extract the returned `post_view` and map it via
    /// `neutralPostView(fromV3:)`/`neutralPostView(fromV4:)`.
    ///
    /// Only the fields Spud plausibly needs are exposed here (name, community, url, body, nsfw,
    /// language); v3/v4's other `CreatePost` fields (`alt_text`, `honeypot`, `custom_thumbnail`,
    /// v4-only `tags`/`scheduled_publish_time_at`) are omitted as YAGNI and always sent as nil.
    ///
    /// - Parameters:
    ///   - name: the post title.
    ///   - communityId: the community to post in.
    ///   - url: optional link url.
    ///   - body: optional markdown body.
    ///   - nsfw: whether to flag the post not-safe-for-work.
    ///   - languageId: language of the post content; nil lets the server pick a default.
    /// - Returns: the neutral `PostView` for the newly created post.
    /// - Note: requires authentication.
    func createPostNeutral(
        name: String,
        communityId: Int64,
        url: String?,
        body: String?,
        nsfw: Bool?,
        languageId: Int64?
    ) async throws -> PostView {
        switch apiVersion {
        case .v3:
            try await createPostNeutralV3(
                name: name,
                communityId: communityId,
                url: url,
                body: body,
                nsfw: nsfw,
                languageId: languageId
            )
        case .v4:
            try await createPostNeutralV4(
                name: name,
                communityId: communityId,
                url: url,
                body: body,
                nsfw: nsfw,
                languageId: languageId
            )
        case .piefed:
            throw LemmyApiError.unsupportedByDialect(operation: "createPost")
        }
    }
}

private extension LemmyApi {
    /// v3 path: reuses the exact request-building and response-branching shape as
    /// ``createPost(communityID:name:url:body:nsfw:altText:customThumbnail:)``, narrowing
    /// `communityId`/`languageId` down to v3's `Int32`-backed ids, then maps the extracted v3
    /// `post_view` up to the neutral shape.
    func createPostNeutralV3(
        name: String,
        communityId: Int64,
        url: String?,
        body: String?,
        nsfw: Bool?,
        languageId: Int64?
    ) async throws -> PostView {
        let communityID = try v3CommunityID(communityId)
        let languageID = try languageId.map(v3LanguageID)

        let response: Operations.createPost.Output
        do {
            response = try await client.createPost(body: .json(.init(
                name: name,
                community_id: communityID,
                url: url,
                body: body,
                nsfw: nsfw,
                language_id: languageID
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

    /// v4 path: calls the v4 generated client's `CreatePost` operation, passing `communityId`/
    /// `languageId` through unchanged (v4's `CommunityId`/`LanguageId` are already `Int64`), then
    /// maps the extracted v4 `post_view` near-directly to the neutral shape. v4's `CreatePost`
    /// only documents the `ok` response for this operation (no `unauthorized`/`badRequest` cases
    /// like v3), so anything else falls through to `.undocumented`.
    func createPostNeutralV4(
        name: String,
        communityId: Int64,
        url: String?,
        body: String?,
        nsfw: Bool?,
        languageId: Int64?
    ) async throws -> PostView {
        let response: LemmyKitV4Generated.Operations.CreatePost.Output
        do {
            response = try await v4Client.CreatePost(body: .json(.init(
                language_id: languageId,
                nsfw: nsfw,
                body: body,
                url: url,
                community_id: communityId,
                name: name
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
