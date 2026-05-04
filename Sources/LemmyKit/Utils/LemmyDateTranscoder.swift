//
// Copyright (c) 2024, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation
import OpenAPIRuntime

struct LemmyDateTranscoder: DateTranscoder {
    struct EncodingNotSupported: Error, CustomStringConvertible {
        var description: String {
            "LemmyDateTranscoder is decode-only — no Lemmy endpoint we use sends a Date in a request body."
        }
    }

    func decode(_ value: String) throws -> Date {
        try Date(lemmyFormat: value)
    }

    func encode(_: Date) throws -> String {
        throw EncodingNotSupported()
    }
}
