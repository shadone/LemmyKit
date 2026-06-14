//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime

public extension LemmyApi {
    /// Fetch the raw bytes of a pict-rs image.
    ///
    /// This is a pict-rs binary route: the success response is the image
    /// content itself (`image/*`), not JSON. The body is streamed as an
    /// ``OpenAPIRuntime/HTTPBody`` and collected fully in-memory here, so this
    /// is a thin convenience for callers that need the bytes directly rather
    /// than fetching the image by URL.
    ///
    /// - Parameters:
    ///   - fileName: the pict-rs file alias (e.g. `abc123.jpg`) to fetch.
    ///   - format: an optional format to transcode the returned image into.
    ///   - thumbnail: when set, request a thumbnail fitting inside a square of
    ///     this many points per side.
    ///   - maxBytes: the maximum number of bytes to accumulate in memory.
    /// - Returns: the raw image bytes.
    func getImage(
        fileName: String,
        format: ImageFormat? = nil,
        thumbnail: Int32? = nil,
        maxBytes: Int = 50 * 1024 * 1024
    ) async throws -> Data {
        let response: Operations.getImage.Output
        do {
            response = try await client.getImage(
                path: .init(filename: fileName),
                query: .init(format: format?.payload, thumbnail: thumbnail)
            )
        } catch {
            throw LemmyApiError(from: error)
        }

        switch response {
        case let .ok(response):
            switch response.body {
            case let .image__ast_(body):
                do {
                    return try await Data(collecting: body, upTo: maxBytes)
                } catch {
                    throw LemmyApiError.failedToDeserializeResponse(underlyingError: error)
                }
            }

        case .notFound:
            throw LemmyApiError.unknownServerError(httpStatusCode: 404, error: nil)

        case let .undocumented(statusCode, _):
            throw LemmyApiError.unknownServerError(httpStatusCode: statusCode, error: nil)
        }
    }
}

private extension ImageFormat {
    /// The generated query payload matching this format.
    var payload: Operations.getImage.Input.Query.formatPayload {
        switch self {
        case .apng: .apng
        case .avif: .avif
        case .gif: .gif
        case .jpg: .jpg
        case .jxl: .jxl
        case .png: .png
        case .webp: .webp
        }
    }
}
