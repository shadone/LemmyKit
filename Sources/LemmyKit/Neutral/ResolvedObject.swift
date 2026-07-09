//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The version-neutral result of resolving a federated ActivityPub object -- a post, comment,
/// community, or person -- by its url or fully-qualified name, see
/// ``LemmyApi/resolveObjectNeutral(query:)``.
///
/// Both backends can resolve to exactly one of these four kinds. v4 additionally supports
/// resolving to a `MultiCommunity` (a community-of-communities); that kind has no neutral
/// counterpart in this phase and is therefore never represented here -- a query that resolves to
/// one is treated the same as a query that resolves to nothing at all (`resolveObjectNeutral`
/// returns nil), see `Adapters/ResolvedObjectV4Mapping.swift`'s header.
public enum ResolvedObject: Sendable, Equatable {
    /// The query resolved to a post.
    case post(PostView)

    /// The query resolved to a comment.
    case comment(CommentView)

    /// The query resolved to a community.
    case community(CommunityView)

    /// The query resolved to a person.
    case person(PersonView)

    /// The resolved `PostView`, or nil if this is not `.post`.
    public var post: PostView? {
        if case let .post(value) = self { value } else { nil }
    }

    /// The resolved `CommentView`, or nil if this is not `.comment`.
    public var comment: CommentView? {
        if case let .comment(value) = self { value } else { nil }
    }

    /// The resolved `CommunityView`, or nil if this is not `.community`.
    public var community: CommunityView? {
        if case let .community(value) = self { value } else { nil }
    }

    /// The resolved `PersonView`, or nil if this is not `.person`.
    public var person: PersonView? {
        if case let .person(value) = self { value } else { nil }
    }
}
