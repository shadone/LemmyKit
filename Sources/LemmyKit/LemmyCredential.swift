//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct LemmyCredential: Codable {
    let jwt: String

    public init(jwt: String) {
        self.jwt = jwt
    }
}

public extension LemmyCredential {
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

    static func fromString(_ stringValue: String) throws -> LemmyCredential {
        guard let data = stringValue.data(using: .utf8) else {
            fatalError()
        }
        return try JSONDecoder().decode(self, from: data)
    }
}
