# Changelog

All notable changes to LemmyKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While pre-1.0, breaking changes bump the minor version.

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

[0.5.0]: https://github.com/shadone/LemmyKit/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/shadone/LemmyKit/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/shadone/LemmyKit/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/shadone/LemmyKit/compare/0.2.0...0.2.1
