# LemmyKit

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
