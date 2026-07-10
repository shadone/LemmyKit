//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// An id narrowing from the neutral `Int64` down to v3's `Int32` wire types failed because the
/// value doesn't fit.
///
/// Lemmy's Postgres schema stores every id as a 32-bit integer, so a real v3 (or v4) server can
/// never hand back an id outside `Int32`'s range; seeing one here means a caller constructed a
/// bogus id or LemmyKit itself has a bug, not that the server did anything unusual.
enum V3IDConversionError: Error, Equatable {
    /// `id` doesn't fit in `Int32`.
    case idOutOfRange(Int64)
}

/// Narrows a neutral post id down to v3's `Int32`-backed `PostID`.
///
/// v3's mutation wrappers (``LemmyApi/votePostNeutral(id:direction:)``,
/// ``LemmyApi/savePostNeutral(id:saved:)``, ``LemmyApi/hidePostNeutral(id:hidden:)``) use this
/// rather than a trapping `Int32(_:)` init: an out-of-range id should never happen in practice
/// (see ``V3IDConversionError``), so it's surfaced as a catchable ``LemmyApiError/unknown(_:)``
/// instead of crashing the process.
///
/// - Parameter id: the neutral post id to narrow.
/// - Returns: the equivalent v3 `PostID`.
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``V3IDConversionError/idOutOfRange(_:)`` if
///   `id` doesn't fit in `Int32`.
func v3PostID(_ id: Int64) throws -> Components.Schemas.PostID {
    guard let narrowed = Int32(exactly: id) else {
        throw LemmyApiError.unknown(V3IDConversionError.idOutOfRange(id))
    }
    return Components.Schemas.PostID(narrowed)
}

/// Narrows a neutral comment id down to v3's `Int32`-backed `CommentID`. See ``v3PostID(_:)``.
///
/// - Parameter id: the neutral comment id to narrow.
/// - Returns: the equivalent v3 `CommentID`.
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``V3IDConversionError/idOutOfRange(_:)`` if
///   `id` doesn't fit in `Int32`.
func v3CommentID(_ id: Int64) throws -> Components.Schemas.CommentID {
    guard let narrowed = Int32(exactly: id) else {
        throw LemmyApiError.unknown(V3IDConversionError.idOutOfRange(id))
    }
    return Components.Schemas.CommentID(narrowed)
}

/// Narrows a neutral community id down to v3's `Int32`-backed `CommunityID`. See
/// ``v3PostID(_:)``.
///
/// - Parameter id: the neutral community id to narrow.
/// - Returns: the equivalent v3 `CommunityID`.
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``V3IDConversionError/idOutOfRange(_:)`` if
///   `id` doesn't fit in `Int32`.
func v3CommunityID(_ id: Int64) throws -> Components.Schemas.CommunityID {
    guard let narrowed = Int32(exactly: id) else {
        throw LemmyApiError.unknown(V3IDConversionError.idOutOfRange(id))
    }
    return Components.Schemas.CommunityID(narrowed)
}

/// Narrows a neutral person id down to v3's `Int32`-backed `PersonID`. See ``v3PostID(_:)``.
///
/// - Parameter id: the neutral person id to narrow.
/// - Returns: the equivalent v3 `PersonID`.
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``V3IDConversionError/idOutOfRange(_:)`` if
///   `id` doesn't fit in `Int32`.
func v3PersonID(_ id: Int64) throws -> Components.Schemas.PersonID {
    guard let narrowed = Int32(exactly: id) else {
        throw LemmyApiError.unknown(V3IDConversionError.idOutOfRange(id))
    }
    return Components.Schemas.PersonID(narrowed)
}

/// Narrows a neutral language id down to v3's `Int32`-backed `LanguageID`. See ``v3PostID(_:)``.
///
/// Unlike the id conversions above, v4's `LanguageId` is already `Int64` (matching the neutral
/// type exactly), so only the v3 content-mutation endpoints (``LemmyApi/createPostNeutral(name:communityId:url:body:nsfw:languageId:)``,
/// ``LemmyApi/createCommentNeutral(content:postId:parentId:languageId:)``) need this narrowing.
///
/// - Parameter id: the neutral language id to narrow.
/// - Returns: the equivalent v3 `LanguageID`.
/// - Throws: ``LemmyApiError/unknown(_:)`` wrapping ``V3IDConversionError/idOutOfRange(_:)`` if
///   `id` doesn't fit in `Int32`.
func v3LanguageID(_ id: Int64) throws -> Components.Schemas.LanguageID {
    guard let narrowed = Int32(exactly: id) else {
        throw LemmyApiError.unknown(V3IDConversionError.idOutOfRange(id))
    }
    return Components.Schemas.LanguageID(narrowed)
}
