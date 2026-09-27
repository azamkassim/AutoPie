#!/usr/bin/env bash
set -euo pipefail

# Verified installer for the source-identical upstream release.
# Fork main at creation: 10e85e2bdd4ebb0c8dedf995b23ac5763d60c16b
# Upstream tag:          v0.19.0-beta
# APK SHA-256:           3cbf48102124ddd20b36637074ef40b032b55146f3afd07a5c6eddbf1078ccd6

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${AUTOPIE_INSTALL_TAG:-v0.19.0-beta}"
ASSET="${AUTOPIE_INSTALL_ASSET:-AutoPie-v0.19.0-beta-aarch64.apk}"
EXPECTED_SHA256="${AUTOPIE_INSTALL_SHA256:-3cbf48102124ddd20b36637074ef40b032b55146f3afd07a5c6eddbf1078ccd6}"
DOWNLOAD_URL="${AUTOPIE_INSTALL_URL:-https://github.com/cryptrr/AutoPie/releases/download/${TAG}/${ASSET}}"
DEST_DIR="${AUTOPIE_INSTALL_DIR:-$HOME/downloads/autopie}"
DEST="$DEST_DIR/$ASSET"

if [[ -f "$ROOT_DIR/scripts/autopie-doctor-termux.sh" ]]; then
  bash "$ROOT_DIR/scripts/autopie-doctor-termux.sh"
fi

for tool in curl sha256sum termux-open; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool" >&2
    echo "In Termux, run: pkg update && pkg install -y curl coreutils termux-tools" >&2
    exit 1
  fi
done

ARCH="$(uname -m 2>/dev/null || true)"
case "$ARCH" in
  aarch64|arm64) ;;
  *)
    echo "Unsupported architecture: ${ARCH:-unknown}. This APK is arm64-v8a only." >&2
    exit 1
    ;;
esac

mkdir -p "$DEST_DIR"
TMP="$DEST.part"
trap 'rm -f "$TMP"' EXIT

echo "Downloading AutoPie $TAG..."
curl --fail --location --retry 3 --retry-delay 2 \
  --proto '=https' --tlsv1.2 \
  --output "$TMP" "$DOWNLOAD_URL"

ACTUAL_SHA256="$(sha256sum "$TMP" | awk '{print $1}')"
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
  echo "SHA-256 verification FAILED." >&2
  echo "Expected: $EXPECTED_SHA256" >&2
  echo "Actual:   $ACTUAL_SHA256" >&2
  exit 1
fi

mv -f "$TMP" "$DEST"
trap - EXIT

echo "Verified APK:"
echo "  $DEST"
echo "  sha256:$ACTUAL_SHA256"
echo
echo "Opening Android Package Installer..."
if ! termux-open --view "$DEST"; then
  echo "Could not open the package installer automatically." >&2
  echo "Open this APK manually from Files: $DEST" >&2
  exit 1
fi

echo
echo "Android requires a visible user confirmation for sideloaded APKs."
echo "Tap Install in the system installer. If blocked, allow 'Install unknown apps' for Termux and run this script again."
