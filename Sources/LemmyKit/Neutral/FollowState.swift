//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

/// The relationship between the signed-in account and a community's follow/subscribe state.
///
/// This is a 4-state model matching v4's `CommunityFollowerState` (plus `.notFollowing` for
/// "no relationship at all"). `.approvalRequired` and `.denied` are **v4-only**: a v3 backend
/// only ever produces `.notFollowing`, `.pending`, or `.accepted`, because v3's
/// `SubscribedType` collapses "pending because the community requires approval" and "pending
/// but denied" into the same `Pending` case. Adapters map:
/// - v4: `community_actions.follow_state` (nil → `.notFollowing`).
/// - v3: `SubscribedType.Subscribed` → `.accepted`, `.Pending` → `.pending`,
///   `.NotSubscribed` → `.notFollowing`.
public enum FollowState: Sendable, Equatable {
    /// No follow relationship exists; the account does not follow the community.
    case notFollowing

    /// A follow request has been sent and is awaiting the community's decision. This is the
    /// only "in-flight" state a v3 backend can produce.
    case pending

    /// v4-only: the community requires manual mod approval to join, and the request has not
    /// yet been acted on. A v3 backend collapses this into `.pending`.
    case approvalRequired

    /// v4-only: the community's moderators denied the follow request. A v3 backend collapses
    /// this into `.pending` (it has no way to represent a denial as distinct from "waiting").
    case denied

    /// The follow request was accepted; the account actively follows the community.
    case accepted
}
