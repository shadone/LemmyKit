//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Sets the `User-Agent` header on every request.
///
/// Without this the URLSession transport sends iOS' default agent, whose
/// `CFNetwork/...` token is denylisted by some Lemmy instances' nginx (a bare
/// 403). A plain, identifying agent avoids that and is good HTTP etiquette.
struct UserAgentMiddleware: ClientMiddleware {
    let userAgent: String

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        request.headerFields[.userAgent] = userAgent
        return try await next(request, body, baseURL)
    }
}
