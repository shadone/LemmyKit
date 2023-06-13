//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

struct LemmyServerError: Error {
    let message: String
}

enum LemmyApiError: Error {
    case failedToSerializeRequest
    case responseContainsNoData

    case serverError(message: String)
    case unknownServerError
}
