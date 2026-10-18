# Fork review — 18 October 2026

Base fork: `94a339e6483f630552c5ddec221d0b818adc4117`.
Upstream merged: `8c5e83b119b3d7517141c704b8d17a6490a8820b` (`v0.19.3-beta`).

The fork's two unique commits add installation documentation, a pinned APK
installer and a Termux compatibility doctor; they do not modify Android runtime
code. The upstream merge applies cleanly and preserves those files.

Priority upstream changes reviewed:

- `00766a76a1c4f6576016c05c1544775dd7ec8dc5`: shell exports now always quote
  values literally and validate environment variable names. The old behavior
  trusted values already surrounded by quotes, which could expose shell expansion.
- `5534af8195d23ecd27a2d77600d03df9631617bb`: comment-only/empty recipe handling
  avoids the previous first-element exception during executable discovery.
- Shared-file/text routing, package restoration, output presentation and theme
  updates are also included. This is a focused review, not a complete security
  audit of all upstream code.

Local changes:

- Installer defaults now pin v0.19.3-beta, using the SHA-256 digest published by
  GitHub's release asset metadata:
  `c1d140a165f09af8433e8d0b855a363f8a394477038a1b1cb1951f9e444ef7a7`.
  Actual APK bytes are verified by the installer at download time; this review
  did not independently download/install the APK or verify its signing certificate.
- Doctor reports failed/unavailable package queries as unconfirmed, falls back
  from failed rish to pm, and explicitly returns success when no failures exist.
  Previously its final false arithmetic condition could return status 1 even
  after a successful check, aborting the installer under `set -e`.
- Offline share recipe counts text and extracts unique HTTP(S) links. It performs
  no network calls, file reads, shell evaluation or business-system integration.
  AutoPie's normal command logs still apply.

Validation:

- Five Python host tests passed, including actual embedded recipe execution,
  literal shell syntax, Unicode, duplicate/malformed links, size limits, and
  mocked rish failure with pm fallback.
- Bash syntax checks and `git diff --check` passed.
- Android unit tests could not start: Gradle 9.1.0 download failed with
  `Network is unreachable`. No Android SDK/device execution is claimed.

Before merging/releasing: run Android host integration tests per README-tests.md,
then install the verified upstream APK on a test device and complete the share
sample in this folder's README. Do not call this phone-tested until that check
has actually passed.
