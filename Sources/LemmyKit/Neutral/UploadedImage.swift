//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// The version-neutral result of uploading an image, see
/// ``LemmyApi/uploadImageNeutral(imageData:fileName:)``.
///
/// This is v4-shaped: v4's `UploadImageResponse` is `{ filename, image_url }`, both always
/// present, so `imageURL` is non-nil on a v4-backed upload and `deleteToken` is always nil (v4
/// exposes no way to delete an uploaded image via this response). v3's `ImageUploadResponse` has
/// no `image_url` of its own -- only a bare pict-rs file alias (`file`) and a `delete_token` -- so
/// a v3-backed upload synthesizes `imageURL` from the instance's pict-rs base url plus that alias
/// (the same synthesis `uploadImage(imageData:fileName:mimeType:)` already does) and always
/// carries a non-nil `deleteToken`.
public struct UploadedImage: Sendable, Equatable {
    /// The server-assigned filename: v3's pict-rs file alias (`file`), or v4's `filename`.
    public let filename: String

    /// The fully-qualified url the image can be fetched from. Always present on a v4-backed
    /// upload (v4's `image_url`, parsed as a `URL`); synthesized from the instance's pict-rs base
    /// url on a v3-backed one (see this type's header) -- nil only if that url synthesis or v4's
    /// `image_url` string somehow fails to parse as a `URL`.
    public let imageURL: URL?

    /// pict-rs delete token, present only on a v3-backed upload. Always nil on a v4-backed
    /// upload.
    public let deleteToken: String?

    public init(filename: String, imageURL: URL?, deleteToken: String?) {
        self.filename = filename
        self.imageURL = imageURL
        self.deleteToken = deleteToken
    }
}
