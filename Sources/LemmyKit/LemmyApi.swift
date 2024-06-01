//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public final class LemmyApi {
    let client: Client
    let authorizationMiddleware = AuthorizationMiddleware()

    let credential: LemmyCredential?

    // MARK: Public

    public let instanceHostname: String

    // MARK: Functions

    /// Creates a new api instance for the given Lemmy instance.
    /// - Parameter instanceUrl: base url for the instance e.g. "https://lemmy.world"
    /// - Parameter credential: Lemmy JWT auth for making authenticated requests on behalf of a user account.
    public init(instanceUrl: URL, credential: LemmyCredential?) {
        let instanceHostname: String?
        if #available(iOS 16.0, *) {
            instanceHostname = instanceUrl.host(percentEncoded: false)
        } else {
            instanceHostname = instanceUrl.host
        }
        self.instanceHostname = instanceHostname ?? instanceUrl.absoluteString

        self.credential = credential

        client = Client(
            serverURL: instanceUrl,
            configuration: .init(dateTranscoder: LemmyDateTranscoder()),
            transport: URLSessionTransport(),
            middlewares: [authorizationMiddleware]
        )
    }
}
