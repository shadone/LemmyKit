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
        jsonDecoder.dateDecodingStrategy = .custom { decoder in
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
        }
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

        let statusCode = httpUrlResponse.statusCode
        switch statusCode {
        case 200...299:
            guard let responseData else {
                throw LemmyApiError.responseContainsNoData
            }
            do {
                return try jsonDecoder.decode(Endpoint.Response.self, from: responseData)
            } catch {
                throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
            }

        case 500...599:
            throw LemmyApiError.serverUnavailable(httpStatusCode: statusCode)

        default:
            guard let responseData else {
                throw LemmyApiError.unknownServerError(httpStatusCode: statusCode)
            }

            let errorResponse: ErrorResponse
            do {
                errorResponse = try jsonDecoder.decode(ErrorResponse.self, from: responseData)
            } catch {
                throw LemmyApiError.unknownServerError(httpStatusCode: statusCode)
            }
            throw LemmyApiError.serverError(.init(from: errorResponse.error))
        }
    }
}

// MARK: - Get Posts

public extension LemmyApi {
    func getPosts(
        _ request: GetPosts.Request
    ) async throws -> GetPosts.Response {
        try await self.request(GetPosts.self, request)
    }

    func getPosts(
        _ request: GetPosts.Request
    ) -> AnyPublisher<GetPosts.Response, LemmyApiError> {
        Future {
            try await self.getPosts(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Post

public extension LemmyApi {
    func getPost(
        _ request: GetPost.Request
    ) async throws -> GetPost.Response {
        try await self.request(GetPost.self, request)
    }

    func getPost(
        _ request: GetPost.Request
    ) -> AnyPublisher<GetPost.Response, LemmyApiError> {
        Future {
            try await self.getPost(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Comments

public extension LemmyApi {
    func getComments(
        _ request: GetComments.Request
    ) async throws -> GetComments.Response {
        try await self.request(GetComments.self, request)
    }

    func getComments(
        _ request: GetComments.Request
    ) -> AnyPublisher<GetComments.Response, LemmyApiError> {
        Future {
            try await self.getComments(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Create Post Like

public extension LemmyApi {
    func createPostLike(
        _ request: CreatePostLike.Request
    ) async throws -> CreatePostLike.Response {
        try await self.request(CreatePostLike.self, request)
    }

    func createPostLike(
        _ request: CreatePostLike.Request
    ) -> AnyPublisher<CreatePostLike.Response, LemmyApiError> {
        Future {
            try await self.createPostLike(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Create Comment Like

public extension LemmyApi {
    func createCommentLike(
        _ request: CreateCommentLike.Request
    ) async throws -> CreateCommentLike.Response {
        try await self.request(CreateCommentLike.self, request)
    }

    func createCommentLike(
        _ request: CreateCommentLike.Request
    ) -> AnyPublisher<CreateCommentLike.Response, LemmyApiError> {
        Future {
            try await self.createCommentLike(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Site

public extension LemmyApi {
    func getSite(
        _ request: GetSite.Request
    ) async throws -> GetSite.Response {
        try await self.request(GetSite.self, request)
    }

    func getSite(
        _ request: GetSite.Request
    ) -> AnyPublisher<GetSite.Response, LemmyApiError> {
        Future {
            try await self.getSite(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Login

public extension LemmyApi {
    func login(
        _ request: Login.Request
    ) async throws -> Login.Response {
        try await self.request(Login.self, request)
    }

    func login(
        _ request: Login.Request
    ) -> AnyPublisher<Login.Response, LemmyApiError> {
        Future {
            try await self.login(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Register

public extension LemmyApi {
    func register(
        _ request: Register.Request
    ) async throws -> Register.Response {
        try await self.request(Register.self, request)
    }

    func register(
        _ request: Register.Request
    ) -> AnyPublisher<Register.Response, LemmyApiError> {
        Future {
            try await self.register(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Person Details

public extension LemmyApi {
    func getPersonDetails(
        _ request: GetPersonDetails.Request
    ) async throws -> GetPersonDetails.Response {
        try await self.request(GetPersonDetails.self, request)
    }

    func getPersonDetails(
        _ request: GetPersonDetails.Request
    ) -> AnyPublisher<GetPersonDetails.Response, LemmyApiError> {
        Future {
            try await self.getPersonDetails(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Get Person Mentions

public extension LemmyApi {
    func getPersonMentions(
        _ request: GetPersonMentions.Request
    ) async throws -> GetPersonMentions.Response {
        try await self.request(GetPersonMentions.self, request)
    }

    func getPersonMentions(
        _ request: GetPersonMentions.Request
    ) -> AnyPublisher<GetPersonMentions.Response, LemmyApiError> {
        Future {
            try await self.getPersonMentions(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Resolve Object

public extension LemmyApi {
    /// Fetch a non-local / federated object.
    func resolveObject(
        _ request: ResolveObject.Request
    ) async throws -> ResolveObject.Response {
        try await self.request(ResolveObject.self, request)
    }

    /// Fetch a non-local / federated object.
    func resolveObject(
        _ request: ResolveObject.Request
    ) -> AnyPublisher<ResolveObject.Response, LemmyApiError> {
        Future {
            try await self.resolveObject(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Search

public extension LemmyApi {
    /// Search Lemmy
    func search(
        _ request: Search.Request
    ) async throws -> Search.Response {
        try await self.request(Search.self, request)
    }

    /// Search Lemmy
    func search(
        _ request: Search.Request
    ) -> AnyPublisher<Search.Response, LemmyApiError> {
        Future {
            try await self.search(request)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Mark Post as Read

public extension LemmyApi {
    /// Mark a post as read.
    func markPostAsRead(
        _ request: MarkPostAsRead.Request
    ) async throws -> MarkPostAsRead.Response {
        try await self.request(MarkPostAsRead.self, request)
    }

    /// Mark a post as read.
    func markPostAsRead(
        _ request: MarkPostAsRead.Request
    ) -> AnyPublisher<MarkPostAsRead.Response, LemmyApiError> {
        Future {
            try await self.markPostAsRead(request)
        }.eraseToAnyPublisher()
    }
}
