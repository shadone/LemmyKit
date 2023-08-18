//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct PostResponse: Decodable {
    public let post_view: PostView

    public init(post_view: PostView) {
        self.post_view = post_view
    }
}
