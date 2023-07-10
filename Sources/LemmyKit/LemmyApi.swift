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

    // MARK: Public

    public let instanceHostname: String

    // MARK: Functions

    /// Creates a new api instance for the given Lemmy instance.
    /// - Parameter instanceUrl: base url for the instance e.g. "https://lemmy.world"
    public init(instanceUrl: URL) {
        let instanceHostname: String?
        if #available(iOS 16.0, *) {
            instanceHostname = instanceUrl.host(percentEncoded: false)
        } else {
            instanceHostname = instanceUrl.host
        }
        self.instanceHostname = instanceHostname ?? instanceUrl.absoluteString

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
            (responseData, urlResponse) = try await session.data(for: urlRequest)
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

            let errorResponse: ErrorResponse
            do {
                errorResponse = try jsonDecoder.decode(ErrorResponse.self, from: responseData)
            } catch {
                throw LemmyApiError.unknownServerError
            }
            throw LemmyApiError.serverError(.init(from: errorResponse.error))
        }
    }
}

// MARK: - Get Posts

extension LemmyApi {
    public func getPosts(
        _ request: GetPosts.Request
    ) async throws -> GetPosts.Response {
        return try await self.request(GetPosts.self, request)
    }

    public func getPosts(
        _ request: GetPosts.Request
    ) -> AnyPublisher<GetPosts.Response, LemmyApiError> {
        Future {
            try await self.getPosts(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Comments

extension LemmyApi {
    public func getComments(
        _ request: GetComments.Request
    ) async throws -> GetComments.Response {
        return try await self.request(GetComments.self, request)
    }

    public func getComments(
        _ request: GetComments.Request
    ) -> AnyPublisher<GetComments.Response, LemmyApiError> {
        Future {
            try await self.getComments(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Create Post Like

extension LemmyApi {
    public func createPostLike(
        _ request: CreatePostLike.Request
    ) async throws -> CreatePostLike.Response {
        return try await self.request(CreatePostLike.self, request)
    }

    public func createPostLike(
        _ request: CreatePostLike.Request
    ) -> AnyPublisher<CreatePostLike.Response, LemmyApiError> {
        Future {
            try await self.createPostLike(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Create Comment Like

extension LemmyApi {
    public func createCommentLike(
        _ request: CreateCommentLike.Request
    ) async throws -> CreateCommentLike.Response {
        return try await self.request(CreateCommentLike.self, request)
    }

    public func createCommentLike(
        _ request: CreateCommentLike.Request
    ) -> AnyPublisher<CreateCommentLike.Response, LemmyApiError> {
        Future {
            try await self.createCommentLike(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Site

extension LemmyApi {
    public func getSite(
        _ request: GetSite.Request
    ) async throws -> GetSite.Response {
        return try await self.request(GetSite.self, request)
    }

    public func getSite(
        _ request: GetSite.Request
    ) -> AnyPublisher<GetSite.Response, LemmyApiError> {
        Future {
            try await self.getSite(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Login

extension LemmyApi {
    public func login(
        _ request: Login.Request
    ) async throws -> Login.Response {
        return try await self.request(Login.self, request)
    }

    public func login(
        _ request: Login.Request
    ) -> AnyPublisher<Login.Response, LemmyApiError> {
        Future {
            try await self.login(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Register

extension LemmyApi {
    public func register(
        _ request: Register.Request
    ) async throws -> Register.Response {
        return try await self.request(Register.self, request)
    }

    public func register(
        _ request: Register.Request
    ) -> AnyPublisher<Register.Response, LemmyApiError> {
        Future {
            try await self.register(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Person Details

extension LemmyApi {
    public func getPersonDetails(
        _ request: GetPersonDetails.Request
    ) async throws -> GetPersonDetails.Response {
        return try await self.request(GetPersonDetails.self, request)
    }

    public func getPersonDetails(
        _ request: GetPersonDetails.Request
    ) -> AnyPublisher<GetPersonDetails.Response, LemmyApiError> {
        Future {
            try await self.getPersonDetails(request)
        }.eraseToAnyPublisher()
    }
}
