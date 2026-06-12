//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Builds a `multipart/form-data` request body by hand.
///
/// The swift-openapi-generated client can technically express multipart bodies,
/// but pict-rs (Lemmy's image backend) is strict about the wire format: it wants
/// the field name `images[]` and a `filename` in the `Content-Disposition`
/// header of the file part. Constructing the body manually keeps that contract
/// explicit and unit-testable, independent of the runtime's part serializer.
///
/// Pure value type, so the produced `Data` is deterministic and `Sendable`.
struct MultipartFormData: Sendable {
    let boundary: String

    private var parts: [Data] = []

    init(boundary: String = "Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    /// HTTP `Content-Type` header value for this body, including the boundary.
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// Append a file part with an explicit filename and content type.
    mutating func appendFile(
        name: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) {
        var header = ""
        header += "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n"
        header += "\r\n"

        var part = Data()
        part.append(Data(header.utf8))
        part.append(data)
        part.append(Data("\r\n".utf8))
        parts.append(part)
    }

    /// Serialize all parts plus the closing boundary into the request body.
    func encode() -> Data {
        var body = Data()
        for part in parts {
            body.append(part)
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }
}
