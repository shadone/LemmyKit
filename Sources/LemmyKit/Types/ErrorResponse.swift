//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct ErrorResponse: Decodable {
    public let error: String
    public let message: String?

    init(
        error: String,
        message: String?
    ) {
        self.error = error
        self.message = message
    }
}
