//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import OpenAPIRuntime
import OpenAPIURLSession

/// A client for a single Lemmy instance.
///
/// Wraps the generated OpenAPI client and exposes one async method per Lemmy
/// endpoint (see the `LemmyApi+*` extensions). Create one per instance,
/// optionally with a ``LemmyCredential`` to act on behalf of a user account.
public actor LemmyApi {
    let client: Client
    let v4Client: LemmyKitV4Generated.Client
    /// The PieFed `/api/alpha` client, built only when ``apiVersion`` is `.piefed`; nil otherwise.
    /// Unlike `client`/`v4Client` (always built, unused unless dispatched to), this is optional
    /// because `PiefedClient` isn't a swift-openapi-generated `Client` with a cheap no-op
    /// construction -- it carries the same `instanceUrl`/credential/transport/userAgent this
    /// instance was configured with, so building it unconditionally would be redundant state, not
    /// just dead code. See ``ApiVersion/piefed``.
    let piefedClient: PiefedClient?
    let authorizationMiddleware: AuthorizationMiddleware

    /// `User-Agent` sent on every request (generated client calls and the
    /// hand-written pict-rs upload alike). See ``UserAgentMiddleware``.
    let userAgent: String

    let credential: LemmyCredential?

    // MARK: Public

    /// The instance host, e.g. `lemmy.world`, derived from the base url.
    public let instanceHostname: String

    /// Base url for the instance e.g. `https://lemmy.world`. Retained so
    /// hand-written transports (such as the pict-rs multipart image upload)
    /// can build absolute urls without going through the generated client.
    let instanceUrl: URL

    /// Which backend (v3's `client`, v4's `v4Client`, or PieFed's `piefedClient`) the
    /// version-neutral `LemmyApi+*Neutral` methods dispatch to. See ``ApiVersion``.
    public let apiVersion: ApiVersion

    // MARK: Functions

    /// Creates an api client for the given Lemmy instance, using
    /// `URLSessionTransport` for networking.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - credential: the session credential for authenticated requests, or nil for anonymous access.
    ///   - userAgent: the `User-Agent` to send on every request.
    ///   - apiVersion: which generated backend the version-neutral methods dispatch to.
    ///     Defaults to `.v3`.
    public init(
        instanceUrl: URL,
        credential: LemmyCredential?,
        userAgent: String = "LemmyKit",
        apiVersion: ApiVersion = .v3
    ) {
        self.instanceUrl = instanceUrl
        let instanceHostname: String?
        if #available(iOS 16.0, *) {
            instanceHostname = instanceUrl.host(percentEncoded: false)
        } else {
            instanceHostname = instanceUrl.host
        }
        self.instanceHostname = instanceHostname ?? instanceUrl.absoluteString

        self.credential = credential
        self.userAgent = userAgent
        self.apiVersion = apiVersion
        authorizationMiddleware = AuthorizationMiddleware(token: credential?.jwt)

        let transport = URLSessionTransport()
        client = Client(
            serverURL: instanceUrl,
            configuration: .init(dateTranscoder: LemmyDateTranscoder()),
            transport: transport,
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
        v4Client = LemmyKitV4Generated.Client(
            serverURL: instanceUrl,
            transport: transport,
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
        piefedClient = apiVersion == .piefed
            ? PiefedClient(baseURL: instanceUrl, token: credential?.jwt, transport: transport, userAgent: userAgent)
            : nil
    }

    /// Creates an api client backed by a caller-supplied transport.
    ///
    /// Intended for tests: inject a stub `ClientTransport` to return canned
    /// responses without hitting the network. Production code uses
    /// ``init(instanceUrl:credential:userAgent:apiVersion:)`` which wires up
    /// `URLSessionTransport`.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - credential: the session credential for authenticated requests, or nil for anonymous access.
    ///   - transport: the transport used to issue requests.
    ///   - userAgent: the `User-Agent` to send on every request.
    ///   - apiVersion: which generated backend the version-neutral methods dispatch to.
    ///     Defaults to `.v3`.
    public init(
        instanceUrl: URL,
        credential: LemmyCredential?,
        transport: any ClientTransport,
        userAgent: String = "LemmyKit",
        apiVersion: ApiVersion = .v3
    ) {
        self.instanceUrl = instanceUrl
        let instanceHostname: String?
        if #available(iOS 16.0, *) {
            instanceHostname = instanceUrl.host(percentEncoded: false)
        } else {
            instanceHostname = instanceUrl.host
        }
        self.instanceHostname = instanceHostname ?? instanceUrl.absoluteString

        self.credential = credential
        self.userAgent = userAgent
        self.apiVersion = apiVersion
        authorizationMiddleware = AuthorizationMiddleware(token: credential?.jwt)

        client = Client(
            serverURL: instanceUrl,
            configuration: .init(dateTranscoder: LemmyDateTranscoder()),
            transport: transport,
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
        v4Client = LemmyKitV4Generated.Client(
            serverURL: instanceUrl,
            transport: transport,
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
        piefedClient = apiVersion == .piefed
            ? PiefedClient(baseURL: instanceUrl, token: credential?.jwt, transport: transport, userAgent: userAgent)
            : nil
    }
}
