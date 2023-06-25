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
}
