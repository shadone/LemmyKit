//
// Copyright (c) 2023, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Combine

// Original author: Natascha Fadeeva
// https://tanaschita.com/20220822-bridge-async-await-to-combine-future/

extension Future where Failure == LemmyApiError {
    convenience init(asyncFunc: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch let error as LemmyApiError {
                    promise(.failure(error))
                } catch {
                    fatalError("unexpected error type \(error)")
                }
            }
        }
    }
}
