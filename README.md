# SwiftManchu

SwiftManchu is a Manchu-Chinese-English dictionary app rebuilt with modern Swift and SwiftUI.

The current `main` branch is the active rewrite. The original 2014-2015 iOS/UIKit project is preserved on `2015-legacy`.

## Status

- SwiftUI interface with a searchable dictionary list and detail view
- Shared Swift core for dictionary models and SQLite reads
- Bundled dictionary data: 3,435 words and 1,052 example sentences
- Local macOS app launch supported without an Apple Developer account
- Package manifest declares iOS 17+ and macOS 14+ targets, but current local validation is macOS-only

## Requirements

- macOS
- Apple Command Line Tools or Xcode
- Swift 6-capable toolchain

This repository currently uses a direct `swiftc` build path for local macOS testing because the development machine's Command Line Tools / SDK combination cannot run SwiftPM reliably. Once a matching full Xcode install is available, `Package.swift` should become the normal build entrypoint.

## Run on macOS

```sh
./script/build_and_run.sh
```

To build, launch, and verify the process is running:

```sh
./script/build_and_run.sh --verify
```

The script creates a local app bundle at:

```text
dist/SwiftManchu.app
```

Build artifacts are ignored by Git.

## Project Layout

```text
Sources/SwiftManchuCore/      Shared dictionary models and SQLite store
Sources/SwiftManchu/          SwiftUI app, views, and bundled resources
Tests/SwiftManchuCoreTests/   Small core checks
script/build_and_run.sh       Local macOS build/run entrypoint
SwiftManchu/                  Preserved legacy iOS project files and source data
```

## Branches

- `main`: active modern SwiftUI rewrite
- `2015-legacy`: original Swift/UIKit app from the 2014-2015 codebase

## Notes

No Apple Developer account is required for the current macOS local workflow. iOS work should wait until a proper Xcode project or working SwiftPM/Xcode setup is in place.
