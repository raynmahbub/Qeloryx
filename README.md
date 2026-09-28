# Qeloryx

**Hear Beyond. Build Beyond.**

Qeloryx is an iOS music-player project built around an offline-first library, playback, discovery, and a focused Midnight Aurora interface. The repository contains the app, reusable Swift packages, engineering documentation, and GitHub Actions workflows.

> **Status:** Early development (`0.0.1-dev`). Expect incomplete features and breaking changes. This is not an App Store release. The first development release will be published as a GitHub prerelease when its tagged build passes CI.

## Project at a glance

- **Platform:** iOS 17+
- **Language/tooling:** Swift 5.9+, Swift Package Manager, XcodeGen, Xcode
- **App:** SwiftUI interface with AVFoundation-backed platform integration
- **Packages:** `QeloryxCore`, `QeloryxDesignSystem`, and `QeloryxPlatform`
- **Dependencies:** No external Swift package dependencies currently declared

## Features in development

The codebase includes playback and queue components, library and metadata handling, indexed search, lyrics models, download workflows, Taste DNA/recommendation components, a design system, and iOS platform adapters. Some screens and data paths are prototypes or use sample data; feature presence in source does not imply production readiness or a completed end-to-end user experience.

## Requirements

- macOS with Xcode installed (the project configuration currently targets Xcode 15.4 / Swift 5.9)
- XcodeGen (`brew install xcodegen`) to generate the native project
- SwiftLint (`brew install swiftlint`) for local linting

## Build and test

```sh
# Portable package build and tests
swift build
swift test

# Generate the iOS project and build for an available simulator SDK
xcodegen generate
xcodebuild -project Qeloryx.xcodeproj \
  -scheme Qeloryx \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build

# Lint
swiftlint lint --strict
```

For local setup helpers, see [`Scripts/bootstrap.sh`](Scripts/bootstrap.sh), [`Scripts/lint.sh`](Scripts/lint.sh), and [`Scripts/generate-docs.sh`](Scripts/generate-docs.sh). Generated Xcode projects, build output, and signing assets should not be committed.

## Repository layout

```text
App/                 SwiftUI app entry point and app resources
Core/                Portable domain and engine code
DesignSystem/        Shared visual foundations and components
Features/            Feature presentation and application logic
Platform/            iOS-specific adapters and integrations
Tests/               Swift package and app tests
Docs/                Architecture decisions, build and release guidance
Scripts/             Local developer and release utilities
.github/workflows/   CI, build, performance checks, and release automation
```

## CI and releases

Pull requests and branch pushes are checked by GitHub Actions. The checks cover Swift package build/tests, lint, generated iOS project build, and documentation/repository sanity. A failed required check is a signal to fix the underlying issue; workflows must not silently turn build or test failures into success.

Development releases use annotated semantic-version tags, for example `v0.0.1-dev.1`. Pushing a tag triggers validation and creates a GitHub **prerelease** with the build artifact and generated release notes. The artifact is an **unsigned simulator build** for evaluation; it is not an installable App Store IPA and cannot be distributed to physical devices without signing. See [`Docs/RELEASE_FLOW.md`](Docs/RELEASE_FLOW.md) and [`CHANGELOG.md`](CHANGELOG.md).

To start a development release, first ensure the desired commit is on the intended release branch and CI is green, then create and push a unique tag:

```sh
git tag -a v0.0.1-dev.1 -m "Qeloryx 0.0.1 development 1"
git push origin v0.0.1-dev.1
```

Do not reuse or force-update published tags. For TestFlight/App Store distribution, configure Apple signing credentials and a separate protected distribution workflow; none are stored in this repository.

## Engineering documentation

- [Build readiness](Docs/BUILD_READINESS.md)
- [Release flow](Docs/RELEASE_FLOW.md)
- [Architecture Decision Records](Docs/ADR/)
- [Engineering plans](Docs/EPL/)
- [Implementation logs](Docs/IL/)
- [Research notes](Docs/SHM/)

## Contributing

Use focused branches and pull requests, describe user-visible changes, and add or update tests and documentation where appropriate. Keep secrets, signing material, user audio, and generated build products out of Git. See [CHANGELOG.md](CHANGELOG.md) for recorded project changes.

## License

No license file is currently included. Unless a license is added, all rights are reserved and reuse or redistribution is not granted by default.
