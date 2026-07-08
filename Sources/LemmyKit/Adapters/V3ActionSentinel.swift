//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The `Date` a V3 backend adapter writes into a neutral action's `*At` field when v3 tells us
/// *that* something happened but not *when*.
///
/// v3's wire shape has no per-viewer timestamps at all -- only bare booleans (`saved`, `read`,
/// `hidden`, `creator_blocked`) and a signed vote score (`my_vote`). The neutral action structs
/// (`PostActions`, `CommunityActions`, `PersonActions`) are v4-shaped and expect a `Date?`, so a
/// v3 adapter has two choices when the underlying state is known to be true: leave the field
/// `nil` (losing the "it happened" signal) or write a placeholder. This constant is the
/// placeholder, used only when the corresponding v3 boolean is `true`.
///
/// It is fixed at the Unix epoch specifically so that it is obviously wrong if a caller ever
/// mistakes it for a real timestamp (e.g. sorts or displays it directly) -- a strong signal to
/// fix the call site. Every neutral action struct exposes derived `is*`/`vote`/
/// `resolvedFollowState` properties that read the presence of the `*At` field, never its value;
/// call sites should always prefer those over reading a raw date, which keeps v3- and
/// v4-backed views indistinguishable to consumers.
let v3ActionSentinel = Date(timeIntervalSince1970: 0)
