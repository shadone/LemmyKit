//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// An authenticated Lemmy session credential: the JWT issued by a login.
///
/// Pass one to ``LemmyApi`` to make requests on behalf of a user account;
/// omit it for anonymous access.
public struct LemmyCredential: Codable, Sendable {
    let jwt: String

    /// Creates a credential wrapping a Lemmy session JWT.
    /// - Parameter jwt: the JSON Web Token returned by a successful login.
    public init(jwt: String) {
        self.jwt = jwt
    }
}

public extension LemmyCredential {
    /// Serializes the credential to a JSON string, e.g. for keychain storage.
    func toString() -> String {
        let data: Data

        do {
            // TODO: shall we decode jwt and store the metadata e.g. claims?
            data = try JSONEncoder().encode(self)
        } catch {
            fatalError("Failed to encode credential: \(error.localizedDescription)")
        }

        return String(data: data, encoding: .utf8)!
    }

    /// Reconstructs a credential from a string produced by ``toString()``.
    /// - Parameter stringValue: the serialized credential string.
    static func fromString(_ stringValue: String) throws -> LemmyCredential {
        guard let data = stringValue.data(using: .utf8) else {
            fatalError()
        }
        return try JSONDecoder().decode(self, from: data)
    }
}
