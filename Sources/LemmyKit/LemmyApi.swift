//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// A client for a single Lemmy instance.
///
/// Wraps the generated OpenAPI client and exposes one async method per Lemmy
/// endpoint (see the `LemmyApi+*` extensions). Create one per instance,
/// optionally with a ``LemmyCredential`` to act on behalf of a user account.
public actor LemmyApi {
    let client: Client
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

    // MARK: Functions

    /// Creates an api client for the given Lemmy instance, using
    /// `URLSessionTransport` for networking.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - credential: the session credential for authenticated requests, or nil for anonymous access.
    ///   - userAgent: the `User-Agent` to send on every request.
    public init(instanceUrl: URL, credential: LemmyCredential?, userAgent: String = "LemmyKit") {
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
        authorizationMiddleware = AuthorizationMiddleware(token: credential?.jwt)

        client = Client(
            serverURL: instanceUrl,
            configuration: .init(dateTranscoder: LemmyDateTranscoder()),
            transport: URLSessionTransport(),
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
    }

    /// Creates an api client backed by a caller-supplied transport.
    ///
    /// Intended for tests: inject a stub `ClientTransport` to return canned
    /// responses without hitting the network. Production code uses
    /// ``init(instanceUrl:credential:userAgent:)`` which wires up
    /// `URLSessionTransport`.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - credential: the session credential for authenticated requests, or nil for anonymous access.
    ///   - transport: the transport used to issue requests.
    ///   - userAgent: the `User-Agent` to send on every request.
    public init(
        instanceUrl: URL,
        credential: LemmyCredential?,
        transport: any ClientTransport,
        userAgent: String = "LemmyKit"
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
        authorizationMiddleware = AuthorizationMiddleware(token: credential?.jwt)

        client = Client(
            serverURL: instanceUrl,
            configuration: .init(dateTranscoder: LemmyDateTranscoder()),
            transport: transport,
            middlewares: [authorizationMiddleware, UserAgentMiddleware(userAgent: userAgent)]
        )
    }
}
