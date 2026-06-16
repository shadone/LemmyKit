//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public extension LemmyApi {
    /// Fetch a community by its numeric id.
    ///
    /// - Parameter communityID: the community to fetch.
    func getCommunity(
        communityID: Components.Schemas.CommunityID
    ) async throws -> Components.Schemas.GetCommunityResponse {
        try await getCommunity(query: .init(id: communityID, name: nil))
    }

    /// Fetch a community by its name.
    ///
    /// - Parameter name: a bare name (`gnome`) for a local community or a fully-qualified name (`worldnews@lemmy.world`) for a remote one.
    func getCommunity(
        name: String
    ) async throws -> Components.Schemas.GetCommunityResponse {
        try await getCommunity(query: .init(id: nil, name: name))
    }

    private func getCommunity(
        query: Operations.getCommunity.Input.Query
    ) async throws -> Components.Schemas.GetCommunityResponse {
        let response: Operations.getCommunity.Output
        do {
            response = try await client.getCommunity(query: query)
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
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
}
