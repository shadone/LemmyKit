//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// Parses one of v4's timestamp strings into a `Date`.
///
/// The `-pre` v4 spec doesn't yet annotate its timestamp fields `format: date-time` (confirmed
/// against `Lemmy-OpenAPI-Spec/specs/v4/1.0.0-pre/openapi.yaml` -- e.g. `PostActions.saved_at`
/// and `Post.published_at` are both a bare `type: string`), so swift-openapi-generator emits
/// plain `Swift.String` for every v4 timestamp instead of `Foundation.Date`. This is unlike v3,
/// whose spec does annotate them and which the generated `Client` decodes straight to `Date` via
/// `LemmyDateTranscoder`. Parse v4's strings with the same underlying `Date(lemmyFormat:)`
/// parser v3 uses, so v3- and v4-backed neutral views end up with dates in an identical
/// representation. Returns `nil` for a `nil` input or a string that fails to parse.
func v4Date(_ string: String?) -> Date? {
    guard let string else { return nil }
    return try? Date(lemmyFormat: string)
}

/// As `v4Date(_:)`, for a field the schema marks required.
///
/// Falls back to the Unix epoch if the server ever sends a malformed timestamp. This should
/// never happen in practice -- it exists only so this parser, like the rest of the adapter
/// mapping functions, never throws.
func v4Date(required string: String) -> Date {
    (try? Date(lemmyFormat: string)) ?? Date(timeIntervalSince1970: 0)
}
