//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine
import Foundation

public final class LemmyApi {
    let baseUrl: URL
    let extraHeaders: HTTPHeaders = .init([])

    let session: URLSession = .shared

    let jsonDecoder: JSONDecoder

    /// Creates a new api instance for the given Lemmy instance.
    /// - Parameter instanceUrl: base url for the instance e.g. "https://lemmy.world"
    public init(instanceUrl: URL) {
        baseUrl = URL(string: "/api/v3/", relativeTo: instanceUrl)!

        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let stringValue = try container.decode(String.self)

            do {
                return try Date(lemmyFormat: stringValue)
            } catch {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted with milliseconds e.g '2023-06-13T13:36:53.593094'.",
                    underlyingError: error
                ))
            }
        })
    }

    func request<Endpoint: LemmyApiEndpoint>(
        _ endpoint: Endpoint.Type,
        _ request: Endpoint.Request
    ) async throws -> Endpoint.Response {
        guard let url = URL(string: Endpoint.href, relativeTo: baseUrl) else {
            throw LemmyApiError.failedToSerializeRequest(underlyingError: nil)
        }

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if Endpoint.method == .get {
            do {
                let queryItems = try URLQueryItemsEncoder().encode(request)
                urlComponents?.queryItems = queryItems
            } catch {
                throw LemmyApiError.failedToSerializeRequest(underlyingError: error)
            }
        }

        guard let url = urlComponents?.url else {
            throw LemmyApiError.failedToSerializeRequest(underlyingError: nil)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = Endpoint.method.rawValue
        extraHeaders.headers.forEach {
            urlRequest.addValue($0.value, forHTTPHeaderField: $0.name)
        }

        if Endpoint.method != .get {
            do {
                let requestData = try JSONEncoder().encode(request)
                urlRequest.httpBody = requestData
            } catch {
                throw LemmyApiError.failedToSerializeRequest(underlyingError: error)
            }

            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let responseData: Data?
        let urlResponse: URLResponse?

        do {
            (responseData, urlResponse) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data?, URLResponse?), Error>) in
                session.dataTask(with: urlRequest) { responseData, urlResponse, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (responseData, urlResponse))
                    }
                }.resume()
            }
            //let (responseData, urlResponse) = try await session.data(for: urlRequest)
        } catch {
            throw LemmyApiError.network(error)
        }

        guard let httpUrlResponse = urlResponse as? HTTPURLResponse else {
            fatalError("Not HTTP?")
        }

        switch httpUrlResponse.statusCode {
        case 200..<299:
            guard let responseData = responseData else {
                throw LemmyApiError.responseContainsNoData
            }
            do {
                return try jsonDecoder.decode(Endpoint.Response.self, from: responseData)
            } catch {
                throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
            }

        default:
            guard let responseData = responseData else {
                throw LemmyApiError.unknownServerError
            }

            do {
                let error = try jsonDecoder.decode(ErrorResponse.self, from: responseData)
                throw LemmyApiError.serverError(.init(message: error.error))
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

    public func getPosts(
        type: ListingType? = nil,
        sort: SortType? = nil,
        page: Int? = nil,
        limit: Int? = nil,
        communityId: CommunityId? = nil,
        communityName: String? = nil,
        savedOnly: Bool? = nil
    ) -> AnyPublisher<GetPosts.Response, LemmyApiError> {
        Future { promise in
            Task {
                do {
                    let value = try await self.getPosts(
                        type: type,
                        sort: sort,
                        page: page,
                        limit: limit,
                        communityId: communityId,
                        communityName: communityName,
                        savedOnly: savedOnly
                    )
                    promise(.success(value))
                } catch let error as LemmyApiError {
                    promise(.failure(error))
                } catch {
                    fatalError("unexpected error type \(error)")
                }
            }
        }.eraseToAnyPublisher()
    }
}
