//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import LemmyKitV4Generated
import OpenAPIRuntime
import OpenAPIURLSession

/// Detects which API version a Lemmy instance speaks, for consumers without their own
/// version-detection machinery.
///
/// `LemmyApi` never probes the server itself -- ``ApiVersion`` is always injected explicitly by
/// the caller (see its doc comment) -- so this is a standalone, opt-in tool a consumer can call
/// once (e.g. on first login, or when adding a new instance) to obtain the value to pass in.
///
/// Detection works by requesting `GET {instanceUrl}/api/v4/site` against the v4 generated client:
/// v4 instances answer with `200 ok`; v3 instances don't expose that route and answer `404`.
public enum ApiVersionProbe {
    /// Detects the API version an instance speaks by probing `/api/v4/site`, using
    /// `URLSessionTransport` for networking.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - userAgent: the `User-Agent` to send on the probe request. Pass nil to omit it and use
    ///     the transport's default.
    /// - Returns: ``ApiVersion/v4`` if the probe gets a `2xx` response, ``ApiVersion/v3``
    ///   otherwise -- including on a `404`, a network failure, a timeout, a `5xx`, or any other
    ///   unexpected outcome. Unknown/ambiguous results deliberately fail safe to `.v3`, the
    ///   widely-supported version, rather than throwing: a flaky or slow-to-upgrade instance
    ///   should still be usable.
    public static func detect(instanceUrl: URL, userAgent: String?) async -> ApiVersion {
        await detect(instanceUrl: instanceUrl, transport: URLSessionTransport(), userAgent: userAgent)
    }

    /// Detects the API version an instance speaks, using a caller-supplied transport.
    ///
    /// Intended for tests: inject a stub `ClientTransport` to return canned responses without
    /// hitting the network. Production code uses ``detect(instanceUrl:userAgent:)`` which wires
    /// up `URLSessionTransport`.
    ///
    /// - Parameters:
    ///   - instanceUrl: the instance base url, e.g. `https://lemmy.world`.
    ///   - transport: the transport used to issue the probe request.
    ///   - userAgent: the `User-Agent` to send on the probe request. Pass nil to omit it and use
    ///     the transport's default.
    /// - Returns: ``ApiVersion/v4`` if the probe gets a `2xx` response, ``ApiVersion/v3``
    ///   otherwise. See ``detect(instanceUrl:userAgent:)`` for the full fail-safe rationale.
    public static func detect(
        instanceUrl: URL,
        transport: any ClientTransport,
        userAgent: String?
    ) async -> ApiVersion {
        var middlewares: [any ClientMiddleware] = []
        if let userAgent {
            middlewares.append(UserAgentMiddleware(userAgent: userAgent))
        }

        let client = LemmyKitV4Generated.Client(
            serverURL: instanceUrl,
            transport: transport,
            middlewares: middlewares
        )

        let response: LemmyKitV4Generated.Operations.GetSite.Output
        do {
            response = try await client.GetSite()
        } catch {
            // Network failure, timeout, decoding error, etc. -- fail safe to `.v3`.
            return .v3
        }

        switch response {
        case .ok:
            return .v4

        case .undocumented:
            // `GetSite` only documents the `200` case (see `LemmyApi+GetSiteNeutral.swift`), so a
            // `404` (v3, route doesn't exist) and any other unexpected status both land here.
            // Fail safe to `.v3` for all of them.
            return .v3
        }
    }
}
