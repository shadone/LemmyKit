# LemmyKit

[![Swift versions][swift versions badge]][swift versions]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

Swift API for [Lemmy](https://join-lemmy.org).
This package was made primarily for [Spud](https://github.com/shadone/Spud) app.

## Development

### Install `mint`

We use [mint](https://github.com/yonaskolb/Mint) tool to run Swift cli packages such as `SwiftGen`.

```sh
brew install mint
```

Then install the cli packages that we use as part of the build process.

```sh
mint bootstrap
```

### SwiftFormat

To format the code run `mint run swiftformat .`

[swift versions]: https://swiftpackageindex.com/shadone/LemmyKit
[swift versions badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fshadone%2FLemmyKit%2Fbadge%3Ftype%3Dswift-versions
[platforms]: https://swiftpackageindex.com/shadone/LemmyKit
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fshadone%2FLemmyKit%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/shadone/LemmyKit/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
