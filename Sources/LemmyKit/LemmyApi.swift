//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public final class LemmyApi {
    let baseUrl = URL(string: "https://discuss.tchncs.de/api/v3/")!
    let extraHeaders: HTTPHeaders = .init([])

    let session: URLSession = .shared

    let jsonDecoder: JSONDecoder

    public init() {
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFractionalSeconds]

            guard let date = formatter.date(from: stringValue) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted with milliseconds e.g '2023-06-13T13:36:53.593094'.",
                    underlyingError: nil
                ))
            }

            return date
        })
    }

    func request<Endpoint: LemmyApiEndpoint>(
        _ endpoint: Endpoint.Type,
        _ request: Endpoint.Request
    ) async throws -> Endpoint.Response {
        guard let url = URL(string: Endpoint.href, relativeTo: baseUrl) else {
            throw LemmyApiError.failedToSerializeRequest
        }

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if Endpoint.method == .get {
            let queryItems = try URLQueryItemsEncoder().encode(request)
            urlComponents?.queryItems = queryItems
        }

        guard let url = urlComponents?.url else {
            throw LemmyApiError.failedToSerializeRequest
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = Endpoint.method.rawValue
        extraHeaders.headers.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.name)
        }

        if Endpoint.method != .get {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData

            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (responseData, urlResponse) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data?, URLResponse?), Error>) in
            session.dataTask(with: urlRequest) { responseData, urlResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (responseData, urlResponse))
                }
            }.resume()
        }
//        let (responseData, urlResponse) = try await session.data(for: urlRequest)

        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            fatalError("Not HTTP?")
        }

        switch httpUrlResponse.statusCode {
        case 200..<299:
            guard let responseData = responseData else {
                throw LemmyApiError.responseContainsNoData
            }
            return try jsonDecoder.decode(Endpoint.Response.self, from: responseData)

        default:
            guard let responseData = responseData else {
                throw LemmyApiError.unknownServerError
            }

            do {
                let error = try jsonDecoder.decode(ErrorResponse.self, from: responseData)
                throw LemmyApiError.serverError(message: error.error)
            } catch {
                throw LemmyApiError.unknownServerError
            }
        }
    }

    public func getPosts(
        type: ListingType? = nil,
        sort: SortType? = nil,
        page: Int? = nil,
        limit: Int? = nil,
        communityId: CommunityId? = nil,
        communityName: String? = nil,
        savedOnly: Bool? = nil
    ) async throws -> GetPosts.Response {
        let request = GetPosts.Request(
            type_: type,
            sort: sort,
            page: page,
            limit: limit,
            community_id: communityId,
            community_name: communityName,
            saved_only: savedOnly
        )

        return try await self.request(GetPosts.self, request)
    }
}
