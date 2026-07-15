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
    public func getComments(
        postId: Int64? = nil,
        parentId: Int64? = nil,
        sort: String? = nil,
        maxDepth: Int? = nil
    ) async throws -> PiefedGetCommentsResponse {
        try await get(
            "/api/alpha/comment/list",
            query: [
                ("post_id", postId.map(String.init)),
                ("parent_id", parentId.map(String.init)),
                ("sort", sort),
                ("max_depth", maxDepth.map(String.init)),
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
            // PieFed's error envelope (`{code,message,status}`) is a different shape from Lemmy's
            // (`{error,...}`) -- see `PiefedErrorBody`. Synthesize the existing `ErrorResponse` so
            // downstream consumers (which only know Lemmy's `LemmyApiError.serverError` channel)
            // are unaffected by the dialect. `code` is always present in every captured PieFed
            // error, so it -- not `status` (a human-readable phrase, not a stable code) -- is the
            // more useful `error` value to preserve.
            if let piefedError = try? JSONDecoder().decode(PiefedErrorBody.self, from: data) {
                throw LemmyApiError.serverError(
                    Components.Schemas.ErrorResponse(error: String(piefedError.code), message: piefedError.message)
                )
            }
            throw LemmyApiError.unknownServerError(httpStatusCode: response.status.code, error: nil)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
        }
    }
}
