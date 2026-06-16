//
// Copyright (c) 2026, Denis Dzyubenko <denis@ddenis.info>
//
// SPDX-License-Identifier: BSD-2-Clause
//

import Foundation

/// An image encoding that pict-rs can transcode a fetched image into.
///
/// Used by ``LemmyApi/getImage(fileName:format:thumbnail:maxBytes:)`` to request
/// a specific output format. When omitted, pict-rs returns the image in its
/// stored format.
public enum ImageFormat: String, Sendable, CaseIterable {
    /// Animated PNG.
    case apng
    /// AV1 Image File Format.
    case avif
    /// Graphics Interchange Format.
    case gif
    /// JPEG.
    case jpg
    /// JPEG XL.
    case jxl
    /// Portable Network Graphics.
    case png
    /// WebP.
    case webp
}
