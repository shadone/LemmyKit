//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import XCTest
@testable import LemmyKit

final class MultipartFormDataTests: XCTestCase {
    func testContentTypeIncludesBoundary() {
        let form = MultipartFormData(boundary: "TestBoundary")
        XCTAssertEqual(form.contentType, "multipart/form-data; boundary=TestBoundary")
    }

    func testEncodesSingleFilePartWithPictrsContract() {
        var form = MultipartFormData(boundary: "TestBoundary")
        form.appendFile(
            name: "images[]",
            fileName: "upload.jpg",
            mimeType: "image/jpeg",
            data: Data([0x01, 0x02, 0x03])
        )

        let encoded = form.encode()

        // Split off the trailing binary payload + closing boundary and verify the
        // header bytes are exactly what pict-rs requires (field name `images[]`
        // plus a filename in the Content-Disposition).
        let expectedHeader =
            "--TestBoundary\r\n" +
            "Content-Disposition: form-data; name=\"images[]\"; filename=\"upload.jpg\"\r\n" +
            "Content-Type: image/jpeg\r\n" +
            "\r\n"

        var expected = Data(expectedHeader.utf8)
        expected.append(Data([0x01, 0x02, 0x03]))
        expected.append(Data("\r\n".utf8))
        expected.append(Data("--TestBoundary--\r\n".utf8))

        XCTAssertEqual(encoded, expected)
    }

    func testDefaultBoundaryIsUnique() {
        let a = MultipartFormData()
        let b = MultipartFormData()
        XCTAssertNotEqual(a.boundary, b.boundary)
    }
}
