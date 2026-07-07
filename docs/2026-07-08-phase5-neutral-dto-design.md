# Phase 5 — neutral DTO layer + V3/V4 backend adapters (design)

Date: 2026-07-08
Status: Designed, ready to execute (large multi-step build; execute subagent-driven)
Part of: the Lemmy 1.0 (API v4) initiative. Initiative design +
decisions D1-D8 live in the Spud repo at
`docs/superpowers/specs/2026-07-07-lemmy-v4-initiative-design.md`.
Prereqs met: Phase 2 (v4 spec envelope-stripped) + Phase 3 (`Lemmy.*`
neutral namespace, LemmyKit 0.5.2).

## Goal

LemmyKit exposes ONE version-neutral surface. Its DTOs speak **v4 semantics**
(D3); a **V3 backend adapter emulates upward** and a **V4 backend adapter**
maps near-directly. Which backend runs is chosen by an explicitly injected
`ApiVersion` (D4) — LemmyKit never auto-detects. Spud (already on `Lemmy.*`
after Phase 4) migrates its call sites to the neutral surface in Phase 6.

## Package structure (completes the D7 restructure deferred from Phase 3)

```
LemmyKit (package)
├── LemmyKitV3Generated   ← symlink Sources/.../openapi.yaml → specs/v3/0.19.11; plugin-generated
├── LemmyKitV4Generated   ← symlink → specs/v4/1.0.0-pre (envelope-stripped); plugin-generated
└── LemmyKit (facade)     ← neutral DTOs + LemmyApi + V3/V4 adapters; sole library product
```

- Two generated targets each own their own `Client` + `Components.Schemas` +
  `Operations` namespaces (can't share one target — colliding top-level
  names). Each has its own `openapi-generator-config.yaml` +
  symlinked `openapi.yaml`.
- Generated targets use `accessModifier: package` so the facade sees them but
  Spud cannot. (Fallback if the generator rejects `package`: `public` +
  non-product targets + `internal import` in the facade.)
- The current single-target `Components.Schemas.*` becomes
  `LemmyKitV3Generated`'s. The existing `Lemmy.*` namespace (Phase 3) retargets
  its members from `Components.Schemas.*` to the hand-written neutral DTOs (for
  DTOs) — the ID/enum members may stay as generated-v3 aliases or move to
  neutral enums; decide per-type during build.
- **Spud impact of the retarget is Phase 6, not here** — when `Lemmy.PostView`
  changes from the generated v3 struct to a hand-written neutral struct with a
  different shape, Spud's `Lemmy.PostView`-referencing code must adapt (that is
  exactly Phase 6's v4-semantics adoption).

## ApiVersion + probe

- `public enum ApiVersion: Sendable { case v3, v4 }`.
- `LemmyApi(instanceUrl:credential:apiVersion:userAgent:)` — the actor holds
  the version and dispatches each endpoint method to the V3 or V4 adapter.
- Standalone probe utility (a tool, not implicit): `GET {host}/api/v4/site`
  reachable → `.v4`, 404 → `.v3`. Spud keeps owning detection (SiteRecord
  version / NodeInfo); this is for consumers without that machinery.

## Neutral DTOs — shapes (v4-shaped) + adapter mapping rules

All timestamps are `Date?`; **v3 backends set them `nil`** (state known, time
unknown) — the DTO exposes derived booleans so call sites don't read raw dates.

### PostView / CommentView (the core reshape)
Neutral `PostView`: `post` (with flattened `score/upvotes/downvotes/comments`),
`creator`, `community`, plus nested optional actions:
- `postActions: PostActions?` → `readAt/hiddenAt/savedAt/votedAt: Date?`,
  `voteIsUpvote: Bool?`, `readCommentsAmount: Int64?`, `notificationsMode`.
- `communityActions: CommunityActions?` → `followState: FollowState?`,
  `followedAt/blockedAt/...`.
- `personActions: PersonActions?` → `blockedAt: Date?`, vote tallies, note.
- Derived conveniences on the neutral view: `isSaved/isRead/isHidden: Bool`
  (`*At != nil`), `myVote: VoteDirection` (from `votedAt`+`voteIsUpvote`),
  `followState` (default `.notFollowing` when nil), `unreadComments`
  (`post.comments - postActions.readCommentsAmount`).

**V4 adapter:** near-direct (rename snake→camel; `creator_banned`←v4 field).
**V3 adapter (emulate up):** `post.score/...` ← `counts.{...}`; `savedAt` ←
`saved ? Date.distantPast (sentinel) : nil` — but prefer exposing the boolean
semantics so the sentinel never leaks; `voteIsUpvote/votedAt` ← `my_vote`
(1→(true,sentinel), -1→(false,sentinel), 0→nil); `readCommentsAmount` ←
`post.comments - unread_comments`; `followState` ← map `SubscribedType`
(§FollowState); `personActions.blockedAt` ← `creator_blocked`;
`creator_banned` ← `banned_from_community`.
CommentView is the same pattern with the smaller `CommentActions`
(`savedAt/votedAt/voteIsUpvote` only).

### Page<T> (cursor pagination)
`public struct Page<Item> { let items: [Item]; let nextPage: Cursor?; let prevPage: Cursor? }`,
`Cursor` = opaque `String` (never parsed). **V4:** from `PagedResponse_T_`
(`items/next_page/prev_page`). **V3:** `items` ← `posts`/`comments`; `nextPage`
← v3 `next_page` (feeds only); `prevPage` ← always nil; comment lists (no v3
cursor) → single page, `nextPage = nil`. The V3 adapter internally tracks
page/limit ints behind opaque synthesized cursors.

### Site / MyUser (my_user split)
Neutral `Site` v4-shaped (no `myUser`; single `tagline?`; keep `version`).
Neutral `getMyUser()` is its own operation. **V4:** `GET /account` → MyUserInfo.
**V3:** serve from the cached `getSite().my_user` (no second network call).

### FollowState (4-state)
`public enum FollowState: Sendable { case notFollowing, pending, approvalRequired, denied, accepted }`.
**V4:** `community_actions.follow_state` (nil → `.notFollowing`).
**V3:** `Subscribed→.accepted, Pending→.pending, NotSubscribed→.notFollowing`;
`.approvalRequired`/`.denied` are v4-only (v3 never produces them).

### VoteDirection
`public enum VoteDirection: Sendable { case up, down, none }`. Write:
`vote(_:)`. **V4:** `is_upvote = {up:true, down:false, none:nil}`. **V3:**
`score = {up:1, down:-1, none:0}`. Read: from v4 `votedAt`+`voteIsUpvote`;
from v3 `my_vote` sign.

### Sort (kind + time range)
Neutral `PostSort` = `{active,hot,new,old,top,mostComments,newComments,controversial,scaled}`
+ separate `timeRange: TimeRange?` (a Duration). **V4:** pass both
(`sort` + `time_range_seconds`). **V3:** FOLD into one `SortType` —
`top`+recognized bucket → `TopDay/TopWeek/...`; `top`+arbitrary seconds →
nearest bucket (document the lossiness). Casing differs (v3 PascalCase vs v4
snake_case).

### Notifications (unified inbox — the largest emulation gap)
Neutral `NotificationView { notification; data: NotificationData }`,
`NotificationData = .comment(CommentView) | .post(PostView) | .privateMessage(PrivateMessageView) | .modAction(ModlogView)`;
`listNotifications(type:cursor:unreadOnly:)` returns `Page<NotificationView>`.
**V4:** `GET /account/notification/list` → direct.
**V3:** FAN OUT to `getReplies` + `getPersonMentions` + `getPrivateMessages`,
k-way MERGE by timestamp into one list, synthesize `Notification.kind`
(reply/mention from source; `subscribed`/`mod_action` v4-kinds have no v3
source → omitted), and fabricate cursor paging over v3 page/limit. (Spud
already owns a k-way timeline merge from the Activity feature — mirror it.)

### Person details / content (split)
Neutral `personDetails(...)` → `{ personView, moderates }` (no posts/comments).
Neutral `personContent(cursor:type:)` → `Page<PostOrComment>` where
`PostOrComment = .post(PostView) | .comment(CommentView)`.
**V4:** `GET /person` + `GET /person/content`.
**V3:** one `getPersonDetails` call; expose `person_view`+`moderates` as
details, and its inline `posts[]`+`comments[]` (tagged + sorted) as the content
page, driving pagination via v3 page/limit. Neutral `PersonView` must NOT rely
on `counts` (v4 dropped PersonAggregates); derive counts from v3 only if a
call site needs them.

### Image upload
Neutral `UploadImageResult { filename: String; imageUrl: URL? }`, `upload(imageData:)`.
**V4:** `POST /api/v4/image`, field `image` → `{filename,image_url}`.
**V3:** `POST /pictrs/image`, field `images[]` → take `files[0]`, `file`→
`filename`, SYNTHESIZE `imageUrl` from instance base + pictrs alias; keep
`delete_token` aside for deletion parity.

## Endpoint routing (facade)

Keep the one-file-per-endpoint idiom (`LemmyApi+GetPosts.swift`). Each method
switches on `apiVersion` and calls a `V3Backend` or `V4Backend` method that
owns unwrapping + neutral mapping. The 107 existing v3 wrappers become the V3
backend's starting material. Casing gotcha: v4 operationIds are PascalCase
(`GetSite`, `Login`, `LikePost`), v3 camelCase (`getSite`, `login`,
`createPostLike`) — plus several verbs renamed and `post_ids[]` arrays became
scalar `post_id`, so the V3/V4 wrappers are NOT a pure name transform.

## Build sequence (each step green before the next)

1. Package restructure: add `LemmyKitV3Generated` + `LemmyKitV4Generated`
   targets (symlinks + generator configs); facade depends on both. Verify both
   codegen cleanly (`swift build`). The v4 spec is `-pre` — if codegen chokes,
   fix in the spec repo's overlay/build pass, not here.
2. `ApiVersion` + the facade skeleton dispatching to stub backends.
3. Neutral DTOs (structs/enums above) with the derived conveniences + unit
   tests over the mapping helpers.
4. V3 backend: port the 107 wrappers behind the neutral DTOs (mapping up).
   Recorded-fixture tests (both flavors) using the injectable `ClientTransport`.
5. V4 backend: wrappers over the v4 generated client, mapping to neutral DTOs.
6. Probe utility + `LemmyApi(...apiVersion:)` wiring.
7. Retarget the `Lemmy.*` namespace members to the neutral DTOs; bump LemmyKit
   (minor, pre-1.0 breaking per RELEASING.md → likely 0.6.0). This is the tag
   Spud's Phase 6 pins.

## Risks / notes
- v4 spec is unreleased (`1.0.0-pre`); regenerate at 1.0 beta/rc/final via the
  spec repo's `sync-v4.sh` (D8).
- The notifications merge + person-content split are the hardest V3
  emulations; give them the most test coverage.
- e2e against `voyager.lemmy.ml` / `ds9.lemmy.ml` (official 1.0 test servers).
- Phase 6 (Spud) consumes the 0.6.0 tag — same push-gate dependency as the
  rest of the initiative.
