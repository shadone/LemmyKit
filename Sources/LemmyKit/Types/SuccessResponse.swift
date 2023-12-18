//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

// Source: https://github.com/LemmyNet/lemmy/blob/main/crates/api_common/src/lib.rs

public struct SuccessResponse: Decodable {
    public let success: Bool

    public init(success: Bool) {
        self.success = success
    }
}
