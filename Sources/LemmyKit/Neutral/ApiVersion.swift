//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// Selects which generated backend the `LemmyApi` facade dispatches each request to.
///
/// LemmyKit exposes one version-neutral surface backed by two possible wire protocols:
/// Lemmy's stable v3 API (`LemmyKitV3Generated`) and the upcoming v4 API
/// (`LemmyKitV4Generated`). `ApiVersion` is always **injected explicitly** by the caller
/// when constructing a `LemmyApi` instance — LemmyKit never probes the server or guesses
/// the version itself. Callers that need auto-detection should use a standalone probe
/// (`GET {host}/api/v4/site` reachable → `.v4`, 404 → `.v3`) and pass the resulting value
/// in; Spud, for example, already owns detection via `SiteRecord`/NodeInfo and simply
/// supplies the result here.
public enum ApiVersion: Sendable, Equatable {
    /// Lemmy's stable v3 API. The facade emulates v4-shaped neutral DTOs on top of it.
    case v3

    /// Lemmy's v4 API (the `1.0` rewrite). The facade maps to it near-directly, since the
    /// neutral DTOs are v4-shaped.
    case v4
}
