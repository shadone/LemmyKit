# Releasing LemmyKit

LemmyKit is distributed through Swift Package Manager, which resolves versions
from **git tags** — there is no version string in `Package.swift`. Releasing is
therefore: land the changes, write the changelog, tag, and push.

## Versioning

Semantic Versioning. While the package is pre-1.0:

- **Breaking** API changes (renamed/removed/retyped public symbols, changed
  argument labels, required-vs-optional parameter changes) bump the **minor**
  (`0.4.0` → `0.5.0`).
- Backwards-compatible additions and fixes bump the **patch** (`0.5.0` →
  `0.5.1`).

When in doubt whether a change is breaking, check whether existing call sites
still compile.

## Steps

1. **Make sure `main` is green and clean.**

   ```sh
   swift build
   swift test
   mint run swiftformat --lint Sources Tests   # or your SwiftFormat install
   ```

2. **Check the documentation builds without warnings.** A normal build does not
   run DocC.

   ```sh
   xcodebuild docbuild -scheme LemmyKit \
     -destination 'generic/platform=iOS' \
     -skipPackagePluginValidation -skipMacroValidation \
     -derivedDataPath .build/docs
   ```

   Only `Sources/LemmyKit/` warnings are ours; dependency warnings (Yams,
   swift-algorithms) can be ignored.

3. **Update `CHANGELOG.md`.** Add a `## [X.Y.Z] - YYYY-MM-DD` section describing
   user-facing changes (grouped Added / Changed / Fixed / Removed), flag every
   breaking change and how to migrate it, and add a compare link at the bottom.

4. **Commit the changelog.**

   ```sh
   git add CHANGELOG.md
   git commit -m "docs: changelog for X.Y.Z"
   ```

5. **Tag the release** (annotated, on the changelog commit).

   ```sh
   git tag -a X.Y.Z -m "X.Y.Z"
   ```

6. **Push the branch and the tag.**

   ```sh
   git push origin main
   git push origin X.Y.Z
   ```

7. **(Optional) Create a GitHub release** from the changelog section.

   ```sh
   gh release create X.Y.Z --title X.Y.Z --notes "<changelog section for X.Y.Z>"
   ```

SwiftPackageIndex picks up the new tag automatically; no manual publish step is
required.
