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
    case apng
    case avif
    case gif
    case jpg
    case jxl
    case png
    case webp
}
