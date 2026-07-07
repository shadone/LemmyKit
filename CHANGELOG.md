# Changelog

All notable changes to LemmyKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While pre-1.0, breaking changes bump the minor version.

## [0.5.2] - 2026-07-07

### Added

- Added a neutral `Lemmy` namespace (e.g. `Lemmy.PostView`, `Lemmy.PostID`,
  `Lemmy.SortType`, `Lemmy.GetSiteResponse`, `Lemmy.Post`) aliasing the
  generated `Components.Schemas.*` vocabulary, DTO, model, aggregate, and
  response types, so consumers no longer need the verbose `Components.Schemas.`
  prefix. The members live under a caseless-enum namespace (rather than bare
  top-level typealiases) so common nouns like `Post`, `Comment`, and `Person`
  do not pollute consumers' global scope or shadow other modules' types (e.g.
  Swift Testing's `Comment`). This is stage 1 of the neutral-surface migration:
  purely additive, no breaking change; the existing `Components.Schemas.*`
  surface is untouched and remains fully usable. A future release may retarget
  the DTO aliases to hand-written neutral types.

## [0.5.1] - 2026-06-28

### Added

- `LemmyApi.login` now accepts an optional `totp2faToken`, sent to the server as
  `totp_2fa_token`, so accounts with two-factor (TOTP) authentication enabled
  can sign in. The parameter defaults to `nil`, so existing call sites are
  unaffected.

## [0.5.0] - 2026-06-17

### Fixed

- `getComments` now requests the `All` listing type for post- and parent-scoped
  fetches. Previously, with no listing type the server fell back to its default
  (`Local` on most instances) and silently dropped comments on remote/federated
  communities — a federated post would report a non-zero `comment_count` yet
  return zero comments.

### Changed

- **Breaking:** `getComments` is now four scope-pure overloads —
  `getComments(postID:)`, `getComments(parentID:)`, `getComments(type:)`, and
  `getComments(community:)` — that no longer accept cross-scope parameters. The
  post/parent overloads require their id and request `type_ = .All`; the
  `type:`/`community:` overloads paginate by `page`/`limit`. This makes the
  empty-federated-comments bug unrepresentable rather than merely fixed.
- **Breaking:** `getPosts(community:)` now requires `community` (was optional);
  fetch the frontpage with `getPosts(type:)`.
- **Breaking:** `listCommunities(type:)` now requires `type` and takes
  `ListingType` directly (was an optional `Parameters.Type_`).
- **Breaking:** `listPostLikes(postID:)` and `getSiteMetadata(url:)` now require
  their argument (was optional).
- **Breaking:** the `filter:` parameter on `getComments`/`getPosts` takes a new
  `ContentFilter` value instead of `Set<Filter>`. `liked` and `disliked` are now
  mutually exclusive and cannot be requested together. Migrate `[.saved]` to
  `.saved`; use `.liked` / `.disliked` or `ContentFilter(savedOnly:vote:)`.
- **Breaking:** `login(username:)` renamed to `login(usernameOrEmail:)`.
- **Breaking:** `hidePost(postIds:)` and `markPostAsRead(postIds:)` renamed to
  `postIDs:` (Swift acronym casing).
- **Breaking:** `banPerson` parameter order is now
  `(personID:removeData:reason:expires:)`, matching `banFromCommunity`.
- `getPersonMentions(commentSort:unreadOnly:)` are now optional, matching
  `getReplies` and `getPrivateMessages`.

### Documentation

- Documented parameters across the entire `LemmyApi` endpoint surface and the
  public support types, in a consistent house style. `xcodebuild docbuild` is
  now warning-free for the LemmyKit target.
- Added `CLAUDE.md` working notes and this changelog.

### Internal

- The `getComments` and `getPosts` overloads now forward to a shared internal
  request-and-decode core, removing duplicated response handling.

## [0.4.0] - 2026-05-04

### Changed

- Bumped swift-openapi-generator, swift-openapi-runtime, and
  swift-openapi-urlsession to their latest versions.

## [0.3.0] - 2026-05-04

### Changed

- Adopted Swift 6 language mode and strict concurrency. `LemmyApi` is now an
  `actor`; `Sendable` conformances were added (`LemmyCredential`, `LikeStatus`,
  and others); Combine usage was removed.

### Fixed

- `LemmyDateTranscoder.encode` now throws instead of calling `fatalError`.

## [0.2.1] - 2024-06-10

### Fixed

- Date parsing for Lemmy 0.19.0 responses.

### Changed

- Raised the minimum macOS deployment target to macOS 13 and added a
  SwiftPackageIndex documentation target.

Earlier history (≤ 0.2.0) is available in the git log.

[0.5.2]: https://github.com/shadone/LemmyKit/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/shadone/LemmyKit/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/shadone/LemmyKit/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/shadone/LemmyKit/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/shadone/LemmyKit/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/shadone/LemmyKit/compare/0.2.0...0.2.1
