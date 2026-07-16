//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Parses one of PieFed's `/api/alpha` timestamp strings into a `Date`.
///
/// PieFed's captured fixtures (PieFed 1.7.5, `piefed.social`, 2026-07-15) all carry
/// fractional-seconds ISO-8601 with a trailing `Z` (e.g. `"2026-07-14T22:48:42.055960Z"`),
/// matching Lemmy 0.19's own format -- so this reuses `Date(lemmyFormat:)` rather than
/// duplicating a parser: that initializer already tries the fractional-seconds-with-`Z`,
/// fractional-seconds-without-`Z`, and no-fractional-seconds shapes in order, which covers
/// every PieFed timestamp shape observed plus tolerates ones that aren't. Returns `nil` for a
/// `nil` input or a string that fails to parse against all three shapes.
func piefedDate(_ string: String?) -> Date? {
    guard let string else { return nil }
    return try? Date(lemmyFormat: string)
}
