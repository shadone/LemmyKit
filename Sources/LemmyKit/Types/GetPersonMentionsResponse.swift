//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

public struct GetPersonMentionsResponse: Decodable {
    public let mentions: [PersonMentionView]

    public init(mentions: [PersonMentionView]) {
        self.mentions = mentions
    }
}
