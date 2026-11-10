# Security Policy

## Reporting a vulnerability

Please do **not** open public issues for security-sensitive reports.

Instead, report privately via GitHub Security Advisories on
`raynmahbub/Qeloryx` ("Report a vulnerability"), or contact the maintainers
directly through the repository's configured channels. Include:

- affected component and version,
- reproduction steps or proof of concept,
- impact assessment (data loss, credential exposure, remote execution, …),
- suggested fix, if any.

We aim to acknowledge reports within 5 working days and will credit reporters
who want it once a fix ships.

## Scope and data handling

Qeloryx is an **offline-first** music player:

- The library, playback state, and listening history stay on the device.
- Provider credentials are never stored in the repository or in plain files;
  the `CredentialStoring` seam (`Qeloryx/Services/Security/CredentialStore.swift`)
  isolates secrets behind a keychain-backed adapter.
- Analytics is **opt-in** and disabled by default (`SettingsRepository` →
  `privacy.analyticsEnabled`).
- Downloads and provider traffic go only to endpoints you configure.

## Supported versions

This project is in early development (`0.0.1-dev`) and has not had a stable
release. Security fixes land on `main` and are included in the next tagged
prerelease. There is no stable-version support window yet.

## Sensitive material in this repository

Never commit: API keys, tokens, certificates, provisioning profiles, keychain
dumps, or user audio. `.gitignore` excludes common artifacts; automated
secret scanning is recommended on all forks and clones.
