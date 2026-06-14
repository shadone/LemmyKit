//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public actor LemmyApi {
    let client: Client
    let authorizationMiddleware: AuthorizationMiddleware

    /// `User-Agent` sent on every request (generated client calls and the
    /// hand-written pict-rs upload alike). See ``UserAgentMiddleware``.
    let userAgent: String

    let credential: LemmyCredential?

    // MARK: Public

    public let instanceHostname: String

    /// Base url for the instance e.g. `https://lemmy.world`. Retained so
    /// hand-written transports (such as the pict-rs multipart image upload)
    /// can build absolute urls without going through the generated client.
    let instanceUrl: URL

    // MARK: Functions

    /// Creates a new api instance for the given Lemmy instance.
    /// - Parameter instanceUrl: base url for the instance e.g. "https://lemmy.world"
    /// - Parameter credential: Lemmy JWT auth for making authenticated requests on behalf of a user account.
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

    /// Creates an api instance backed by a caller-supplied transport.
    ///
    /// Intended for tests: inject a stub `ClientTransport` to return canned
    /// responses without hitting the network. Production code uses
    /// ``init(instanceUrl:credential:)`` which wires up `URLSessionTransport`.
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
