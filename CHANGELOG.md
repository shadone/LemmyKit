# Changelog

All notable changes to LemmyKit are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While pre-1.0, breaking changes bump the minor version.

## [Unreleased]

### Added

- `getPostNeutral(id:)` now returns a `PostDetail` (the requested post plus its
  cross-posts) instead of a bare `PostView`. Both backends' `GetPost` response
  carry a `cross_posts` list — other posts linking the same url — which was
  previously dropped; it is now mapped through the same `PostView` adapter as
  the main post and exposed as `PostDetail.crossPosts` (empty when there are
  none). **Breaking:** the return type changed; read `detail.post` for the
  former return value.
- The neutral `Post` now carries `imageWidth: Int?` and `imageHeight: Int?`,
  the pixel dimensions of the post's thumbnail/linked image. Both backends
  expose these on `PostView.image_details`; the value is nil when the server
  reports no image dimensions (a text post, an unresolved link).
- `editPostNeutral` gains an `nsfw: Bool?` parameter (defaulted to nil and
  placed last, so existing callers are unaffected), forwarded to both
  backends' `EditPost` request. nil leaves the flag unchanged.

## [0.6.2] - 2026-07-11

### Added

- A `kind: NotificationKind?` filter on `listNotificationsNeutral`. On v4 this
  maps to `ListNotifications`'s `type_` query filter, sent server-side. On v3
  (no unified inbox) this narrows the fan-out to just the endpoint the
  requested kind needs (`.reply` → `getReplies` only, `.mention` →
  `getPersonMentions` only, `.privateMessage` → `getPrivateMessages` only,
  nil → the original unfiltered three-way fan-out); `.subscribed` and
  `.modAction` have no v3 source, so they call nothing and return an empty
  page rather than throwing.
- `markNotificationAsReadNeutral(id:read:)` and
  `markAllNotificationsAsReadNeutral()` on `LemmyApi`. v4 calls
  `MarkNotificationAsRead`/`MarkAllNotificationsAsRead` directly; v3's
  `markAllNotificationsAsReadNeutral()` reuses the existing `markAllAsRead()`
  wrapper (which does not affect private messages, unlike v4's unified
  inbox), while `markNotificationAsReadNeutral(id:read:)` is a documented
  no-op on v3, since v3 has no unified notification id to mark by.
- `unreadCountsNeutral()` on `LemmyApi`, returning a new `UnreadCounts`
  (`total`, plus optional `replies`/`mentions`/`privateMessages`). v4's
  `GetUnreadCounts` supplies only a combined `notification_count` as
  `total`, leaving the per-kind fields nil; v3's `getUnreadCount` supplies
  the three per-kind counts directly, with `total` synthesized as their sum.

## [0.6.1] - 2026-07-11

### Added

- Four neutral account-feed endpoints on `LemmyApi`: `getSavedPostsNeutral`,
  `getReadPostsNeutral`, `getHiddenPostsNeutral`, `getLikedPostsNeutral`,
  each returning a cursor-paginated `Page<PostView>`. Closes a dual-version
  gap where no neutral saved-posts endpoint existed. On v4, saved/liked
  request the server-side posts-only filter over the combined post/comment
  feed (`ListPersonSaved`/`ListPersonLiked`); read/hidden call `ListPersonRead`/
  `ListPersonHidden` directly. On v3, saved/liked use `getPosts` with
  `saved_only`/`liked_only`; read/hidden have no v3 equivalent (`getPosts`'s
  `show_read`/`show_hidden` only *include* those posts alongside others, they
  don't isolate them), so the v3 path always returns an empty page.

## [0.6.0] - 2026-07-10

Version-neutral dual-version (Lemmy v3 / v4) client surface. LemmyKit can now
talk to both 0.19.x (API v3) and 1.0 (API v4) instances through one neutral
API that speaks v4 semantics, with a v3 backend that emulates upward.

### Added

- A generated `LemmyKitV4Generated` target (the Lemmy 1.0 / API v4 client,
  from the envelope-stripped spec), consumed only by the facade.
- Hand-written neutral DTOs in `Sources/LemmyKit/Neutral/` (v4-shaped:
  flattened counts, nested `*Actions` with timestamp-presence booleans,
  4-state `FollowState`, `VoteDirection`, opaque bidirectional `Page`/`Cursor`,
  `PostSort` + `TimeRange`, unified `NotificationView`/`NotificationEntry`,
  `PostOrComment`, `ResolvedObject`, etc.).
- `ApiVersion` and 26 neutral endpoints on `LemmyApi` (`*Neutral` methods) that
  dispatch on an injected `apiVersion` to the v3 or v4 generated client and map
  the response into the neutral DTOs — feeds, post/comment reads, vote/save/hide,
  create/edit/delete, follow/community, person details + content (v4 split, v3
  interleave), the unified notifications inbox (v3 fan-out + k-way merge),
  search, login/register, settings, private messages, block, resolveObject, and
  image upload.
- `ApiVersionProbe` for consumers without their own version detection (probes
  `/api/v4/site`; defaults to `.v3` on any ambiguity).
- `LemmyApi.init` gains an `apiVersion:` parameter, defaulting to `.v3` so
  existing call sites are unaffected.

### Changed

- **Breaking:** the `Lemmy.*` DTO members with a hand-written neutral
  counterpart (`PostView`, `CommentView`, `CommunityView`, `PersonView`,
  `PrivateMessageView`, `Post`, `Comment`, `Community`, `Person`, `Site`) now
  alias the neutral structs instead of `Components.Schemas.*`, so `Lemmy.PostView`
  is the neutral type. Identifiers, enums, aggregates, and `*Response` members
  are unchanged. The generated `Components.Schemas.*` surface and the existing v3
  wrappers remain available.

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

[0.6.2]: https://github.com/shadone/LemmyKit/compare/0.6.1...0.6.2
[0.6.1]: https://github.com/shadone/LemmyKit/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/shadone/LemmyKit/compare/0.5.2...0.6.0
[0.5.2]: https://github.com/shadone/LemmyKit/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/shadone/LemmyKit/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/shadone/LemmyKit/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/shadone/LemmyKit/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/shadone/LemmyKit/compare/0.2.1...0.3.0
[0.2.1]: https://github.com/shadone/LemmyKit/compare/0.2.0...0.2.1
