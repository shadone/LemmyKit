//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct LoginResponse: Decodable {
    public let jwt: String?
    public let registration_created: Bool
    public let verify_email_sent: Bool

    public init(
        jwt: String? = nil,
        registration_created: Bool,
        verify_email_sent: Bool
    ) {
        self.jwt = jwt
        self.registration_created = registration_created
        self.verify_email_sent = verify_email_sent
    }
}
