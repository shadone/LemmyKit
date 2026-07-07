//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

// This target holds the swift-openapi-generator output for the Lemmy v4 (1.0)
// API, generated from the envelope-stripped spec. It carries no hand-written
// code; the generated `Client` / `Components` / `Operations` are consumed by
// the LemmyKit facade's V4 backend. `package` access keeps them out of
// downstream consumers (only the facade sees them).
