//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// Selects which generated backend the `LemmyApi` facade dispatches each request to.
///
/// LemmyKit exposes one version-neutral surface backed by three possible wire protocols:
/// Lemmy's stable v3 API (`LemmyKitV3Generated`), the upcoming v4 API
/// (`LemmyKitV4Generated`), and PieFed's `/api/alpha` API (`PiefedClient`). `ApiVersion` is
/// always **injected explicitly** by the caller when constructing a `LemmyApi` instance —
/// LemmyKit never probes the server or guesses the version/dialect itself. Callers that need
/// auto-detection should use a standalone probe (`GET {host}/api/v4/site` reachable → `.v4`,
/// 404 → `.v3`) or their own instance-software detection for `.piefed`, and pass the
/// resulting value in; Spud, for example, already owns detection via `SiteRecord`/NodeInfo
/// and simply supplies the result here.
public enum ApiVersion: Sendable, Equatable {
    /// Lemmy's stable v3 API. The facade emulates v4-shaped neutral DTOs on top of it.
    case v3

    /// Lemmy's v4 API (the `1.0` rewrite). The facade maps to it near-directly, since the
    /// neutral DTOs are v4-shaped.
    case v4

    /// PieFed's `/api/alpha` API. Lemmy-shaped at the view level (`PostView`/`CommunityView`
    /// wrappers carry every Lemmy-required flag) but divergent at the entity level (renamed
    /// required fields, a different error envelope) -- see `PiefedClient` and the
    /// `Adapters/*PiefedMapping.swift` adapters that map its wire models into the same neutral
    /// DTOs the v3/v4 dialects produce.
    case piefed
}
