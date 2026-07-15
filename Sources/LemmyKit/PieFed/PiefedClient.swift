//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A transport-based client for PieFed's `/api/alpha` read endpoints.
///
/// Unlike ``LemmyApi`` (which dispatches through swift-openapi-generated `Client`s), `PiefedClient`
/// builds `HTTPRequest`s by hand and issues them directly through the injected `ClientTransport`.
/// PieFed's own OpenAPI spec is live and complete, but its response shapes diverge from Lemmy's at
/// the entity level (renamed required fields, a different error envelope), so generating a third
/// codegen target isn't worthwhile for Phase 1's read-only surface -- a hand-rolled transport call
/// plus the hand-written `Piefed*` wire models (see `PiefedEntities.swift`/`PiefedViews.swift`) is
/// simpler and equally typed. This client decodes those wire models directly, not the shared
/// neutral DTOs -- a later adapter layer maps PieFed's shapes into the same neutral vocabulary the
/// v3/v4 dialects already produce.
public struct PiefedClient: Sendable {
    /// The instance base url, e.g. `https://piefed.social`.
    private let baseURL: URL
    /// The bearer JWT sent as `Authorization: Bearer <token>` on every request, or nil for
    /// anonymous access.
    private let token: String?
    /// The transport used to issue requests -- injectable so tests can stub it without hitting
    /// the network; production callers pass `URLSessionTransport()`.
    private let transport: any ClientTransport
    /// The `User-Agent` sent on every request.
    private let userAgent: String

    /// The maximum number of response bytes collected into memory before giving up. PieFed's
    /// `/api/alpha` responses are JSON listings, not binary payloads, so this is generous headroom
    /// rather than a tight budget (contrast ``LemmyApi/getImage(fileName:format:thumbnail:maxBytes:)``'s
    /// 50 MB image default) -- it exists only to bound a misbehaving/malicious server, not to
    /// constrain a real listing page.
    private static let maxResponseBytes = 10 * 1024 * 1024

    /// The RFC-3986 unreserved character set (`A-Z a-z 0-9 - . _ ~`) -- the ONLY characters left
    /// raw when percent-encoding a query parameter value (see ``percentEncodeQueryValue(_:)``).
    private static let unreservedQueryValueCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    /// Percent-encodes a single query parameter value against the unreserved-only character set,
    /// so `+`, space, and every RFC-3986 sub-delimiter (`; , ' / ? & = # `) are escaped -- unlike
    /// `URLComponents`/`URLQueryItem`, which leaves those raw and lets PieFed's Flask/Werkzeug
    /// query parser misinterpret them (most importantly `+`, which it decodes as a space).
    private static func percentEncodeQueryValue(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: unreservedQueryValueCharacters) ?? value
    }

    /// Creates a client for a single PieFed instance.
    ///
    /// - Parameters:
    ///   - baseURL: the instance base url, e.g. `https://piefed.social`.
    ///   - token: the bearer JWT for authenticated requests, or nil for anonymous access.
    ///   - transport: the transport used to issue requests.
    ///   - userAgent: the `User-Agent` to send on every request.
    public init(baseURL: URL, token: String?, transport: any ClientTransport, userAgent: String) {
        self.baseURL = baseURL
        self.token = token
        self.transport = transport
        self.userAgent = userAgent
    }

    // MARK: - Read endpoints

    /// `GET /api/alpha/site`.
    public func getSite() async throws -> PiefedGetSiteResponse {
        try await get("/api/alpha/site", query: [], operationID: "getSite")
    }

    /// `GET /api/alpha/post/list`.
    ///
    /// - Parameters:
    ///   - type_: the listing scope (`"All"`, `"Local"`, `"Subscribed"`, `"Popular"`,
    ///     `"Moderating"`, `"ModeratorView"`), or nil to let the server default (confirmed live
    ///     against `piefed.social`: an omitted `type_` returns a mixed local+federated listing).
    ///   - sort: the post sort order (e.g. `"Hot"`, `"New"`, `"TopDay"`), or nil for the server
    ///     default. PieFed validates this server-side against a longer enumeration than Lemmy's.
    ///   - communityId: restricts the listing to a single community, or nil for all communities.
    ///   - showNsfw: true to include NSFW posts, false to exclude them, nil for the server default.
    ///   - limit: the page size, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page. PieFed accepts `page=N`
    ///     directly (confirmed live) and echoes the next page number as `next_page` on the
    ///     response, unlike Lemmy v4's opaque cursor.
    public func getPosts(
        type_: String? = nil,
        sort: String? = nil,
        communityId: Int64? = nil,
        showNsfw: Bool? = nil,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> PiefedGetPostsResponse {
        try await get(
            "/api/alpha/post/list",
            query: [
                ("type_", type_),
                ("sort", sort),
                ("community_id", communityId.map(String.init)),
                ("show_nsfw", showNsfw.map(String.init)),
                ("limit", limit.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getPosts"
        )
    }

    /// `GET /api/alpha/post`.
    ///
    /// - Parameter id: the post id.
    public func getPost(id: Int64) async throws -> PiefedGetPostResponse {
        try await get("/api/alpha/post", query: [("id", String(id))], operationID: "getPost")
    }

    /// `GET /api/alpha/comment/list`.
    ///
    /// - Parameters:
    ///   - postId: list comments on this post, or nil to omit the filter.
    ///   - parentId: list only the replies under this comment (for "load more replies"), or nil
    ///     for a whole-tree listing.
    ///   - sort: the comment sort order (e.g. `"Hot"`, `"New"`, `"Old"`), or nil for the server
    ///     default.
    ///   - maxDepth: the maximum reply nesting depth to return, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page. PieFed accepts `page=N`
    ///     directly (confirmed live against `piefed.social`) and echoes the next page number as
    ///     `next_page` on the response, matching `getPosts(type_:sort:communityId:showNsfw:limit:page:)`.
    public func getComments(
        postId: Int64? = nil,
        parentId: Int64? = nil,
        sort: String? = nil,
        maxDepth: Int? = nil,
        page: Int? = nil
    ) async throws -> PiefedGetCommentsResponse {
        try await get(
            "/api/alpha/comment/list",
            query: [
                ("post_id", postId.map(String.init)),
                ("parent_id", parentId.map(String.init)),
                ("sort", sort),
                ("max_depth", maxDepth.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getComments"
        )
    }

    /// `GET /api/alpha/community`.
    ///
    /// - Parameter id: the community id.
    public func getCommunity(id: Int64) async throws -> PiefedGetCommunityResponse {
        try await get("/api/alpha/community", query: [("id", String(id))], operationID: "getCommunity")
    }

    /// `GET /api/alpha/community/list`.
    ///
    /// - Parameters:
    ///   - type_: the listing scope (`"All"`, `"Local"`, `"Subscribed"`, `"Moderating"`,
    ///     `"ModeratorView"`), or nil for the server default.
    ///   - sort: the community sort order (e.g. `"Hot"`, `"New"`, `"TopAll"`), or nil for the
    ///     server default. PieFed validates this against its own (community-specific) enumeration.
    ///   - limit: the page size, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page.
    public func listCommunities(
        type_: String? = nil,
        sort: String? = nil,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> PiefedListCommunitiesResponse {
        try await get(
            "/api/alpha/community/list",
            query: [
                ("type_", type_),
                ("sort", sort),
                ("limit", limit.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "listCommunities"
        )
    }

    /// `GET /api/alpha/search`.
    ///
    /// - Parameters:
    ///   - q: the search query text.
    ///   - type_: the result-type filter (`"Communities"`, `"Posts"`, `"Users"`, `"Url"`,
    ///     `"Comments"`) -- unlike the listing endpoints' `type_`, PieFed requires this one
    ///     (confirmed live: an omitted `type_` is rejected server-side).
    ///   - sort: the result sort order, or nil for the server default.
    ///   - limit: the page size, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page.
    public func search(
        q: String,
        type_: String,
        sort: String? = nil,
        limit: Int? = nil,
        page: Int? = nil
    ) async throws -> PiefedSearchResponse {
        try await get(
            "/api/alpha/search",
            query: [
                ("q", q),
                ("type_", type_),
                ("sort", sort),
                ("limit", limit.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "search"
        )
    }

    /// `GET /api/alpha/resolve_object`.
    ///
    /// - Parameter q: the fully-qualified ActivityPub object url to resolve (a post, comment,
    ///   community, or person).
    public func resolveObject(q: String) async throws -> PiefedResolveObjectResponse {
        try await get("/api/alpha/resolve_object", query: [("q", q)], operationID: "resolveObject")
    }

    // MARK: - Auth + identity

    /// `POST /api/alpha/user/login`. PieFed logs in by **username** (not email, unlike Lemmy
    /// v3's `username_or_email`), with no 2FA field.
    ///
    /// - Parameters:
    ///   - username: the account's username.
    ///   - password: the account's password.
    /// - Returns: the bearer JWT to send as `Authorization: Bearer <jwt>` on every subsequent
    ///   authed request.
    public func login(username: String, password: String) async throws -> PiefedLoginResponse {
        try await send(
            .post, "/api/alpha/user/login",
            body: PiefedLoginRequestBody(username: username, password: password),
            operationID: "login"
        )
    }

    /// `GET /api/alpha/user/me` -- the dedicated my-user route. Note its `follows` list is
    /// observed empty even while subscribed to communities; prefer ``getSiteAuthed()``'s
    /// `my_user` embed when the populated follow list is needed.
    public func userMe() async throws -> PiefedUserMeResponse {
        try await get("/api/alpha/user/me", query: [], operationID: "userMe")
    }

    /// `GET /api/alpha/site` sent with the client's bearer token, which adds the authenticated
    /// account's `my_user` embed (see ``PiefedGetSiteResponse/my_user``).
    ///
    /// Identical to ``getSite()`` -- PieFed rides the authed identity embed on the same route
    /// rather than a dedicated endpoint -- kept as a distinctly-named call site for callers that
    /// specifically want the authed embed (mirrors `getSiteAndMyUserNeutral`'s single-fetch use).
    public func getSiteAuthed() async throws -> PiefedGetSiteResponse {
        try await getSite()
    }

    /// `GET /api/alpha/user/unread_count` -- the Lemmy-compat inbox counters
    /// (mentions/replies/private messages/other).
    public func unreadCount() async throws -> PiefedUnreadCountResponse {
        try await get("/api/alpha/user/unread_count", query: [], operationID: "unreadCount")
    }

    // MARK: - Vote / save / follow

    /// `POST /api/alpha/post/like` -- vote on a post.
    ///
    /// - Parameters:
    ///   - postId: the post id.
    ///   - score: `-1` (downvote), `0` (revert previous vote), or `1` (upvote).
    public func likePost(postId: Int64, score: Int) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/like",
            body: PiefedLikePostRequestBody(post_id: postId, score: score),
            operationID: "likePost"
        )
    }

    /// `POST /api/alpha/comment/like` -- vote on a comment. See ``likePost(postId:score:)`` for
    /// `score` semantics.
    public func likeComment(commentId: Int64, score: Int) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment/like",
            body: PiefedLikeCommentRequestBody(comment_id: commentId, score: score),
            operationID: "likeComment"
        )
    }

    /// `PUT /api/alpha/post/save` -- bookmark/unbookmark a post. **PUT**, not POST (unlike vote).
    public func savePost(postId: Int64, save: Bool) async throws -> PiefedPostResponse {
        try await send(
            .put, "/api/alpha/post/save",
            body: PiefedSavePostRequestBody(post_id: postId, save: save),
            operationID: "savePost"
        )
    }

    /// `PUT /api/alpha/comment/save` -- bookmark/unbookmark a comment. **PUT**, not POST.
    public func saveComment(commentId: Int64, save: Bool) async throws -> PiefedCommentResponse {
        try await send(
            .put, "/api/alpha/comment/save",
            body: PiefedSaveCommentRequestBody(comment_id: commentId, save: save),
            operationID: "saveComment"
        )
    }

    /// `POST /api/alpha/community/follow` -- the membership follow/unfollow (Lemmy's
    /// `follow_community` equivalent). Not to be confused with PieFed's separate
    /// `PUT /community/subscribe` activity-alert toggle, which has no Lemmy v3 equivalent and
    /// isn't exposed here.
    ///
    /// - Returns: the updated ``PiefedCommunityView``, whose `subscribed` is the three-case string
    ///   enum `"NotSubscribed"`/`"Subscribed"`/`"Pending"`, not a bool.
    public func followCommunity(communityId: Int64, follow: Bool) async throws -> PiefedCommunityFollowResponse {
        try await send(
            .post, "/api/alpha/community/follow",
            body: PiefedFollowCommunityRequestBody(community_id: communityId, follow: follow),
            operationID: "followCommunity"
        )
    }

    // MARK: - Mark read / hide

    /// `POST /api/alpha/post/mark_as_read` -- returns a bare `{success}` rather than a post view.
    public func markPostAsRead(postId: Int64, read: Bool) async throws -> PiefedSuccessResponse {
        try await send(
            .post, "/api/alpha/post/mark_as_read",
            body: PiefedMarkPostAsReadRequestBody(post_id: postId, read: read),
            operationID: "markPostAsRead"
        )
    }

    /// `POST /api/alpha/post/hide` -- hide/unhide a post from feeds. PieFed-only; no Lemmy v3
    /// equivalent. Note the wire field is `hidden`, encoded from the `hide` parameter.
    public func hidePost(postId: Int64, hide: Bool) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/hide",
            body: PiefedHidePostRequestBody(post_id: postId, hidden: hide),
            operationID: "hidePost"
        )
    }

    // MARK: - Comment create / edit / delete

    /// `POST /api/alpha/comment`. The comment body field is **`body`** (Lemmy v3: `content`). The
    /// author's own comment is auto-upvoted server-side on creation.
    ///
    /// - Parameters:
    ///   - body: the comment markdown body.
    ///   - postId: the post being commented on.
    ///   - parentId: the parent comment id for a reply, or nil for a top-level comment.
    ///   - languageId: the comment's language id, or nil for the server default.
    public func createComment(
        body: String,
        postId: Int64,
        parentId: Int64? = nil,
        languageId: Int64? = nil
    ) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment",
            body: PiefedCreateCommentRequestBody(
                body: body, post_id: postId, parent_id: parentId, language_id: languageId
            ),
            operationID: "createComment"
        )
    }

    /// `PUT /api/alpha/comment` -- edit a comment's body/language.
    public func editComment(
        commentId: Int64,
        body: String,
        languageId: Int64? = nil
    ) async throws -> PiefedCommentResponse {
        try await send(
            .put, "/api/alpha/comment",
            body: PiefedEditCommentRequestBody(body: body, comment_id: commentId, language_id: languageId),
            operationID: "editComment"
        )
    }

    /// `POST /api/alpha/comment/delete` -- soft-deletes (tombstones) a comment; PieFed's
    /// `/api/alpha` write surface has no hard-delete.
    public func deleteComment(commentId: Int64, deleted: Bool) async throws -> PiefedCommentResponse {
        try await send(
            .post, "/api/alpha/comment/delete",
            body: PiefedDeleteCommentRequestBody(comment_id: commentId, deleted: deleted),
            operationID: "deleteComment"
        )
    }

    // MARK: - Post create / edit / delete

    /// `POST /api/alpha/post`. The author's own post is auto-upvoted server-side on creation.
    ///
    /// - Parameters:
    ///   - communityId: the community to post into.
    ///   - title: the post title.
    ///   - body: the post markdown body, or nil for a link/no-body post.
    ///   - url: the post's link url, or nil for a text post.
    ///   - nsfw: whether the post is marked NSFW, or nil for the server default (`false`).
    ///   - languageId: the post's language id, or nil for the server default.
    public func createPost(
        communityId: Int64,
        title: String,
        body: String? = nil,
        url: String? = nil,
        nsfw: Bool? = nil,
        languageId: Int64? = nil
    ) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post",
            body: PiefedCreatePostRequestBody(
                community_id: communityId, title: title, body: body, url: url, nsfw: nsfw, language_id: languageId
            ),
            operationID: "createPost"
        )
    }

    /// `PUT /api/alpha/post` -- edit a post. Only `postId` is required on the wire; every other
    /// parameter left nil is omitted from the request (the server keeps the existing value).
    public func editPost(
        postId: Int64,
        title: String? = nil,
        body: String? = nil,
        url: String? = nil,
        nsfw: Bool? = nil
    ) async throws -> PiefedPostResponse {
        try await send(
            .put, "/api/alpha/post",
            body: PiefedEditPostRequestBody(post_id: postId, title: title, body: body, url: url, nsfw: nsfw),
            operationID: "editPost"
        )
    }

    /// `POST /api/alpha/post/delete` -- soft-deletes (tombstones) a post.
    public func deletePost(postId: Int64, deleted: Bool) async throws -> PiefedPostResponse {
        try await send(
            .post, "/api/alpha/post/delete",
            body: PiefedDeletePostRequestBody(post_id: postId, deleted: deleted),
            operationID: "deletePost"
        )
    }

    // MARK: - Inbox (Lemmy-compat replies/mentions)

    /// `GET /api/alpha/user/replies` -- the Lemmy-compat comment-reply inbox.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread replies, or nil for the server default (`true`).
    ///   - page: the 1-based page number, or nil for the first page.
    public func getReplies(unreadOnly: Bool? = nil, page: Int? = nil) async throws -> PiefedRepliesResponse {
        try await get(
            "/api/alpha/user/replies",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getReplies"
        )
    }

    /// `GET /api/alpha/user/mentions` -- the Lemmy-compat mention inbox. Shares the `replies`
    /// wrapper key with ``getReplies(unreadOnly:page:)``.
    public func getMentions(unreadOnly: Bool? = nil, page: Int? = nil) async throws -> PiefedRepliesResponse {
        try await get(
            "/api/alpha/user/mentions",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getMentions"
        )
    }

    /// `POST /api/alpha/comment/mark_as_read` -- marks a single reply-inbox notification
    /// read/unread, addressed by the notification's own id (not the comment's id).
    public func markCommentReplyAsRead(commentReplyId: Int64, read: Bool) async throws -> PiefedCommentReplyResponse {
        try await send(
            .post, "/api/alpha/comment/mark_as_read",
            body: PiefedMarkCommentReplyAsReadRequestBody(comment_reply_id: commentReplyId, read: read),
            operationID: "markCommentReplyAsRead"
        )
    }

    /// `POST /api/alpha/user/mark_all_as_read` -- marks the whole Lemmy-compat reply inbox read.
    /// Confirmed live to take no request body.
    public func markAllAsRead() async throws -> PiefedRepliesResponse {
        try await send(
            .post, "/api/alpha/user/mark_all_as_read",
            body: PiefedEmptyRequestBody(),
            operationID: "markAllAsRead"
        )
    }

    // MARK: - Private messages

    /// `GET /api/alpha/private_message/list`.
    ///
    /// - Parameters:
    ///   - unreadOnly: true to return only unread messages, or nil for the server default.
    ///   - page: the 1-based page number, or nil for the first page.
    public func getPrivateMessages(
        unreadOnly: Bool? = nil,
        page: Int? = nil
    ) async throws -> PiefedPrivateMessageListResponse {
        try await get(
            "/api/alpha/private_message/list",
            query: [
                ("unread_only", unreadOnly.map(String.init)),
                ("page", page.map(String.init)),
            ],
            operationID: "getPrivateMessages"
        )
    }

    /// `POST /api/alpha/private_message` -- send a direct message. The DM body field is
    /// **`content`** (matching Lemmy v3; unlike a comment's `body`).
    public func createPrivateMessage(content: String, recipientId: Int64) async throws -> PiefedPrivateMessageResponse {
        try await send(
            .post, "/api/alpha/private_message",
            body: PiefedCreatePrivateMessageRequestBody(content: content, recipient_id: recipientId),
            operationID: "createPrivateMessage"
        )
    }

    /// `POST /api/alpha/private_message/mark_as_read`.
    public func markPrivateMessageAsRead(
        privateMessageId: Int64,
        read: Bool
    ) async throws -> PiefedPrivateMessageResponse {
        try await send(
            .post, "/api/alpha/private_message/mark_as_read",
            body: PiefedMarkPrivateMessageAsReadRequestBody(private_message_id: privateMessageId, read: read),
            operationID: "markPrivateMessageAsRead"
        )
    }

    // MARK: - Person details

    /// `GET /api/alpha/user` -- a person's profile plus (when `includeContent` is true) a page of
    /// their posts and comments.
    ///
    /// - Parameters:
    ///   - personId: the person id to fetch.
    ///   - includeContent: true to include the person's posts/comments, or nil for the server
    ///     default (`false`).
    public func getPersonDetails(
        personId: Int64,
        includeContent: Bool? = nil
    ) async throws -> PiefedPersonDetailsResponse {
        try await get(
            "/api/alpha/user",
            query: [
                ("person_id", String(personId)),
                ("include_content", includeContent.map(String.init)),
            ],
            operationID: "getPersonDetails"
        )
    }

    // MARK: - Transport plumbing

    /// Builds and issues a `GET /api/alpha/...` request through the injected transport, then
    /// decodes the response -- or maps a non-2xx PieFed error envelope / a transport or decode
    /// failure into ``LemmyApiError``.
    ///
    /// - Parameters:
    ///   - path: the request path, e.g. `"/api/alpha/post/list"`.
    ///   - query: query parameters as ordered `(name, value)` pairs; a nil value omits that
    ///     parameter entirely (rather than sending it empty), matching the "server picks its own
    ///     default" semantics every optional PieFed query param has.
    ///   - operationID: an identifier describing the route, forwarded to the transport (mirrors
    ///     what a generated client would pass) for logging/metrics.
    private func get<Response: Decodable & Sendable>(
        _ path: String,
        query: [(String, String?)],
        operationID: String
    ) async throws -> Response {
        // Deliberately NOT `URLComponents`/`URLQueryItem`: its query-value percent-encoding
        // leaves several RFC-3986 sub-delimiters raw -- critically `+`, which PieFed's
        // Flask/Werkzeug backend (`parse_qsl`) decodes as a literal space, silently corrupting
        // free-text values like `search`'s `q` (`"c++"` would arrive server-side as `"c  "`).
        // Encoding against the unreserved-only set below guarantees `+`, space, and every
        // sub-delim are escaped, matching the generated client's `OpenAPIRuntime.isUnreserved`.
        let pairs = query.compactMap { name, value -> String? in
            guard let value else { return nil }
            return "\(name)=\(Self.percentEncodeQueryValue(value))"
        }
        let requestPath = pairs.isEmpty ? path : "\(path)?\(pairs.joined(separator: "&"))"

        var headerFields: HTTPFields = [:]
        headerFields[.userAgent] = userAgent
        if let token {
            headerFields[.authorization] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            method: .get,
            scheme: nil,
            authority: nil,
            path: requestPath,
            headerFields: headerFields
        )

        let response: HTTPResponse
        let responseBody: HTTPBody?
        do {
            (response, responseBody) = try await transport.send(
                request, body: nil, baseURL: baseURL, operationID: operationID
            )
        } catch {
            throw LemmyApiError.network(error)
        }

        let data: Data
        do {
            data = try await Data(collecting: responseBody ?? HTTPBody(), upTo: Self.maxResponseBytes)
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }

        guard response.status.kind == .successful else {
            throw Self.mapNonSuccessResponse(data: data, httpStatusCode: response.status.code)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }
    }

    /// Builds and issues a `POST`/`PUT /api/alpha/...` request carrying a JSON-encoded `Encodable`
    /// body through the injected transport, then decodes the response -- or maps a non-2xx PieFed
    /// error envelope / a transport, encode, or decode failure into ``LemmyApiError``. Mirrors
    /// ``get(_:query:operationID:)`` (same auth header, `User-Agent`, 10 MB response cap, error
    /// decode) plus a `Content-Type: application/json` request header; percent-encoding doesn't
    /// apply to a JSON body.
    ///
    /// - Parameters:
    ///   - method: the HTTP method -- PieFed's write surface uses `POST` for creates/deletes/votes
    ///     and `PUT` for saves/edits (see each public method's doc comment for which).
    ///   - path: the request path, e.g. `"/api/alpha/post/like"`.
    ///   - body: the request body, JSON-encoded verbatim (see `PiefedRequests.swift` -- every
    ///     property name IS the wire key).
    ///   - operationID: an identifier describing the route, forwarded to the transport (mirrors
    ///     what a generated client would pass) for logging/metrics.
    private func send<Response: Decodable & Sendable>(
        _ method: HTTPRequest.Method,
        _ path: String,
        body: some Encodable,
        operationID: String
    ) async throws -> Response {
        var headerFields: HTTPFields = [:]
        headerFields[.userAgent] = userAgent
        headerFields[.contentType] = "application/json"
        if let token {
            headerFields[.authorization] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            method: method,
            scheme: nil,
            authority: nil,
            path: path,
            headerFields: headerFields
        )

        let bodyData: Data
        do {
            bodyData = try JSONEncoder().encode(body)
        } catch {
            // Every request body here is a plain wire-shaped struct with no custom `encode(to:)`
            // logic that could realistically fail -- this should never happen in practice.
            throw LemmyApiError.unknown(error)
        }

        let response: HTTPResponse
        let responseBody: HTTPBody?
        do {
            (response, responseBody) = try await transport.send(
                request, body: HTTPBody(bodyData), baseURL: baseURL, operationID: operationID
            )
        } catch {
            throw LemmyApiError.network(error)
        }

        let data: Data
        do {
            data = try await Data(collecting: responseBody ?? HTTPBody(), upTo: Self.maxResponseBytes)
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }

        guard response.status.kind == .successful else {
            throw Self.mapNonSuccessResponse(data: data, httpStatusCode: response.status.code)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }
    }

    /// Maps a non-2xx PieFed response body into ``LemmyApiError``, shared by ``get(_:query:operationID:)``
    /// and ``send(_:_:body:operationID:)``.
    ///
    /// PieFed's error envelope is a different shape from Lemmy's (`{error,...}`) and is itself
    /// inconsistent across routes -- see ``PiefedErrorBody``'s doc comment for the three observed
    /// shapes. This picks a single semantic token from whichever fields are present (precedence:
    /// `message` ?? `error` ?? `status` ?? `code`) and synthesizes the existing
    /// `LemmyApiError.serverError(ErrorResponse)` channel so downstream consumers (which only know
    /// Lemmy's channel) are unaffected by the dialect. A body that isn't valid JSON at all (or
    /// decodes with every field nil) falls through to `.unknownServerError`.
    private static func mapNonSuccessResponse(data: Data, httpStatusCode: Int) -> LemmyApiError {
        if let piefedError = try? JSONDecoder().decode(PiefedErrorBody.self, from: data) {
            let token = piefedError.message ?? piefedError.error ?? piefedError.status ?? piefedError.code.map(String.init)
            if let token {
                return .serverError(Components.Schemas.ErrorResponse(error: token, message: piefedError.message))
            }
        }
        return .unknownServerError(httpStatusCode: httpStatusCode, error: nil)
    }
}
