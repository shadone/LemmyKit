//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The signed-in account's relationship to a single community: follow/subscribe state,
/// block state, and moderator/ban standing.
///
/// This mirrors v4's `community_actions` object. As with `PostActions`/`CommentActions`, v4
/// encodes most booleans as timestamps (`nil` means "never happened"); a v3 backend adapter has
/// no such timestamps and leaves the `*At` fields `nil` even when the underlying state is
/// known. Call sites should read the derived `isBlocked`/`isModerator`/`resolvedFollowState`
/// properties, never the raw timestamps.
public struct CommunityActions: Sendable, Equatable {
    /// The account's follow/subscribe state, or `nil` if no follow relationship has ever been
    /// established. Read `resolvedFollowState` rather than this raw field, since `nil` and
    /// `.notFollowing` mean the same thing per v4 semantics.
    public var followState: FollowState?

    /// When the account's follow request was accepted, or `nil` if not currently following.
    public var followedAt: Date?

    /// When the account blocked the community, or `nil` if not blocked.
    public var blockedAt: Date?

    /// When the community's moderators banned the account from the community, or `nil` if not
    /// banned.
    public var receivedBanAt: Date?

    /// When a temporary ban from the community expires, or `nil` for no ban or a permanent one.
    public var banExpiresAt: Date?

    /// When the account became a moderator of the community, or `nil` if not a moderator.
    public var becameModeratorAt: Date?

    /// Creates a set of per-viewer community actions. All parameters default to `nil` ("not
    /// done"), which is also the correct value for a signed-out viewer or a community the
    /// account has no relationship with.
    public init(
        followState: FollowState? = nil,
        followedAt: Date? = nil,
        blockedAt: Date? = nil,
        receivedBanAt: Date? = nil,
        banExpiresAt: Date? = nil,
        becameModeratorAt: Date? = nil
    ) {
        self.followState = followState
        self.followedAt = followedAt
        self.blockedAt = blockedAt
        self.receivedBanAt = receivedBanAt
        self.banExpiresAt = banExpiresAt
        self.becameModeratorAt = becameModeratorAt
    }

    /// Whether the account has blocked the community. `true` iff `blockedAt` is set.
    public var isBlocked: Bool { blockedAt != nil }

    /// Whether the account is a moderator of the community. `true` iff `becameModeratorAt` is
    /// set.
    public var isModerator: Bool { becameModeratorAt != nil }

    /// The account's follow state, defaulting to `.notFollowing` when `followState` is `nil`.
    /// Per v4 semantics, the absence of a `follow_state` means "not following" — this is the
    /// property call sites should read instead of the raw optional `followState`.
    public var resolvedFollowState: FollowState { followState ?? .notFollowing }
}
