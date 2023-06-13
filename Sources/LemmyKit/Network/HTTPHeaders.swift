//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

struct HTTPHeaders {
    let headers: [HTTPHeader]

    init(_ headers: [HTTPHeader]) {
        self.headers = headers
    }
}
