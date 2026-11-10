# Contributing to Qeloryx

Thanks for helping build Qeloryx. This document describes the workflow; the architecture itself is documented in [`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) and the ADRs under [`Docs/ADR/`](Docs/ADR/).

## Workflow

1. Branch from `main` (`feature/<topic>`, `fix/<topic>`).
2. Keep changes focused; one concern per pull request.
3. Open a PR and describe the user-visible change (or state plainly that there is none).
4. Update tests and docs when behavior, structure, or guarantees change.

## What must pass before merge

```sh
swift build
swift test
xcodegen generate
xcodebuild -project Qeloryx.xcodeproj -scheme Qeloryx \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build
.github/scripts/lint.sh          # swiftlint + layer architecture checks
```

CI runs the same checks on macOS runners (see `.github/workflows/ci.yml`).

## Architectural rules (enforced by lint)

- **No SwiftUI** in `Qeloryx/Models`, `Qeloryx/Services`, `Qeloryx/Utilities/Helpers`, `Qeloryx/Utilities/Diagnostics`.
- **No AVFoundation** in `Qeloryx/Views`.
- Dependencies point inward: Views → ViewModels → Services → Models. `Platform/` adapts Apple frameworks behind protocols from `Utilities/Helpers/PlatformProtocols.swift`.
- Nothing constructs an engine implicitly. Dependencies are built once by the composition root (`Qeloryx/App/AppCompositionRoot.swift`) and injected.

## Repository conventions

- File names match their primary type; view models live in `Qeloryx/ViewModels/`.
- Generated `Qeloryx.xcodeproj/` is gitignored — edit `project.yml` + `Configuration/*.xcconfig` instead.
- Keep generated artifacts, audio files, and signing material out of Git (see `.gitignore`).
- Don't commit credentials; see [`SECURITY.md`](SECURITY.md).
