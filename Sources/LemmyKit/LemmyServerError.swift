//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public enum LemmyServerError {
    public enum LemmyServerErrorCodes: String {
        /// The specified username or email was not accepted by the Lemmy server.
        case couldnt_find_that_username_or_email

        // The specified password was not accepted by the Lemmy server.
        case password_incorrect
    }

    case value(LemmyServerErrorCodes)
    case unknown(rawValue: String)

    public init(from stringValue: String) {
        if let value = LemmyServerErrorCodes(rawValue: stringValue) {
            self = .value(value)
        } else {
            self = .unknown(rawValue: stringValue)
        }
    }
}
