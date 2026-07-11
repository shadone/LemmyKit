//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import XCTest
@testable import LemmyKit

/// A `ClientTransport` that returns a canned response for every request and captures the *last*
/// outgoing request's operation id and body -- the same capturing shape
/// `AccountActionNeutralTests.swift` uses, extended to also record the operation id so a v4 test
/// can prove the dedicated avatar/banner upload/delete operation was the one issued.
private actor CapturingStubTransport: ClientTransport {
    private let status: Int
    private let responseBody: Data

    private(set) var capturedOperationID: String?
    private(set) var capturedRequestBodyData: Data?

    init(status: Int = 200, responseBody: Data) {
        self.status = status
        self.responseBody = responseBody
    }

    func send(
        _: HTTPRequest,
        body: HTTPBody?,
        baseURL _: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        capturedOperationID = operationID
        if let body {
            capturedRequestBodyData = try await Data(collecting: body, upTo: .max)
        }

        var response = HTTPResponse(status: .init(code: status))
        response.headerFields[.contentType] = "application/json; charset=utf-8"
        return (response, HTTPBody(responseBody))
    }
}

/// A `URLProtocol` that intercepts every `pictrs/image` request issued through `URLSession.shared`,
/// so the v3 avatar/banner set path -- which first uploads to pict-rs via the hand-rolled
/// ``LemmyApi/uploadImage(imageData:fileName:mimeType:)`` (bypassing the injectable
/// `ClientTransport`) before writing `saveUserSettings` -- can be exercised without hitting the
/// network. Mirrors `ResolveUploadNeutralTests.swift`'s `PictrsUploadStubProtocol`; see its header
/// for why `stubbedResponse` is `nonisolated(unsafe)` (process-wide registration serialized by
/// each test's register-set-run-unregister sequencing under XCTest's serial method execution).
private final class PictrsUploadStubProtocol: URLProtocol {
    nonisolated(unsafe) static var stubbedResponse: (status: Int, body: Data) = (200, Data())

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path.contains("pictrs/image") ?? false
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let (status, body) = Self.stubbedResponse
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

/// Proves the neutral avatar/banner push endpoints issue the RIGHT underlying request(s) per
/// version: v3 set = pict-rs upload then `saveUserSettings` carrying the uploaded url; v3 remove =
/// `saveUserSettings` with the field cleared to an empty string; v4 set/remove = the dedicated
/// `UploadUser*`/`DeleteUser*` operation. Follows the vertical
/// `AccountActionNeutralTests.swift`/`ResolveUploadNeutralTests.swift` established: facade dispatch
/// on `ApiVersion`, generated client call (or hand-rolled pict-rs call on the v3 upload), and
/// neutral mapping.
final class ProfileImageNeutralTests: XCTestCase {
    private let pictrsResponseJSON = """
        {"files":[{"file":"abc123.jpg","delete_token":"secret-token"}],"msg":"ok"}
        """
    private let successResponseJSON = """
        {"success":true}
        """

    /// Decodes the transport's captured outgoing request body as a loose JSON dictionary, so
    /// individual fields can be asserted without depending on the generated request type.
    private func capturedJSONBody(_ transport: CapturingStubTransport) async throws -> [String: Any] {
        let capturedData = await transport.capturedRequestBodyData
        let data = try XCTUnwrap(capturedData)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: setAvatarNeutral

    /// v3: uploads to pict-rs, then writes `saveUserSettings` with the synthesized pict-rs url as
    /// `avatar` (not `banner`), returning that url.
    func testSetAvatarNeutralV3UploadsThenSavesAvatarURL() async throws {
        PictrsUploadStubProtocol.stubbedResponse = (200, Data(pictrsResponseJSON.utf8))
        URLProtocol.registerClass(PictrsUploadStubProtocol.self)
        defer { URLProtocol.unregisterClass(PictrsUploadStubProtocol.self) }

        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            transport: transport,
            apiVersion: .v3
        )

        let url = try await api.setAvatarNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "avatar.png",
            contentType: "image/png"
        )

        // Returned url is the synthesized pict-rs url (instance base + "pictrs/image" + alias).
        XCTAssertEqual(url, URL(string: "https://example.invalid/pictrs/image/abc123.jpg"))

        // The single generated-client call was saveUserSettings, carrying that url as `avatar`.
        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "saveUserSettings")
        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["avatar"] as? String, "https://example.invalid/pictrs/image/abc123.jpg")
        XCTAssertNil(body["banner"])
    }

    /// v4: posts the raw bytes to the dedicated `UploadUserAvatar` operation and returns the url
    /// from its response.
    func testSetAvatarNeutralV4CallsUploadUserAvatar() async throws {
        let responseJSON = """
            {"filename":"xyz789.png","image_url":"https://example.invalid/api/v4/image/xyz789.png"}
            """
        let transport = CapturingStubTransport(responseBody: Data(responseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            transport: transport,
            apiVersion: .v4
        )

        let url = try await api.setAvatarNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "avatar.png",
            contentType: "image/png"
        )

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "UploadUserAvatar")
        XCTAssertEqual(url, URL(string: "https://example.invalid/api/v4/image/xyz789.png"))
    }

    // MARK: removeAvatarNeutral

    /// v3: clears by writing an empty-string `avatar` through `saveUserSettings` (empty string, not
    /// nil, is what clears it on Lemmy v3).
    func testRemoveAvatarNeutralV3SavesEmptyAvatar() async throws {
        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.removeAvatarNeutral()

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "saveUserSettings")
        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["avatar"] as? String, "")
        XCTAssertNil(body["banner"])
    }

    /// v4: calls the dedicated bodyless `DeleteUserAvatar` operation.
    func testRemoveAvatarNeutralV4CallsDeleteUserAvatar() async throws {
        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.removeAvatarNeutral()

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "DeleteUserAvatar")
    }

    // MARK: setBannerNeutral

    /// v3: uploads to pict-rs, then writes `saveUserSettings` with the synthesized url as `banner`
    /// (not `avatar`), returning that url.
    func testSetBannerNeutralV3UploadsThenSavesBannerURL() async throws {
        PictrsUploadStubProtocol.stubbedResponse = (200, Data(pictrsResponseJSON.utf8))
        URLProtocol.registerClass(PictrsUploadStubProtocol.self)
        defer { URLProtocol.unregisterClass(PictrsUploadStubProtocol.self) }

        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            transport: transport,
            apiVersion: .v3
        )

        let url = try await api.setBannerNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "banner.png",
            contentType: "image/png"
        )

        XCTAssertEqual(url, URL(string: "https://example.invalid/pictrs/image/abc123.jpg"))

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "saveUserSettings")
        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["banner"] as? String, "https://example.invalid/pictrs/image/abc123.jpg")
        XCTAssertNil(body["avatar"])
    }

    /// v4: posts the raw bytes to the dedicated `UploadUserBanner` operation and returns the url
    /// from its response.
    func testSetBannerNeutralV4CallsUploadUserBanner() async throws {
        let responseJSON = """
            {"filename":"xyz789.png","image_url":"https://example.invalid/api/v4/image/xyz789.png"}
            """
        let transport = CapturingStubTransport(responseBody: Data(responseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: LemmyCredential(jwt: "test-jwt"),
            transport: transport,
            apiVersion: .v4
        )

        let url = try await api.setBannerNeutral(
            imageData: Data([0x01, 0x02, 0x03]),
            fileName: "banner.png",
            contentType: "image/png"
        )

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "UploadUserBanner")
        XCTAssertEqual(url, URL(string: "https://example.invalid/api/v4/image/xyz789.png"))
    }

    // MARK: removeBannerNeutral

    /// v3: clears by writing an empty-string `banner` through `saveUserSettings`.
    func testRemoveBannerNeutralV3SavesEmptyBanner() async throws {
        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v3
        )

        try await api.removeBannerNeutral()

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "saveUserSettings")
        let body = try await capturedJSONBody(transport)
        XCTAssertEqual(body["banner"] as? String, "")
        XCTAssertNil(body["avatar"])
    }

    /// v4: calls the dedicated bodyless `DeleteUserBanner` operation.
    func testRemoveBannerNeutralV4CallsDeleteUserBanner() async throws {
        let transport = CapturingStubTransport(responseBody: Data(successResponseJSON.utf8))
        let api = LemmyApi(
            instanceUrl: URL(string: "https://example.invalid")!,
            credential: nil,
            transport: transport,
            apiVersion: .v4
        )

        try await api.removeBannerNeutral()

        let operationID = await transport.capturedOperationID
        XCTAssertEqual(operationID, "DeleteUserBanner")
    }
}
