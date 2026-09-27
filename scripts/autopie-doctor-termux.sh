#!/usr/bin/env bash
set -uo pipefail

FAILURES=0
WARNINGS=0

pass() { printf 'PASS  %s\n' "$*"; }
warn() { printf 'WARN  %s\n' "$*"; WARNINGS=$((WARNINGS + 1)); }
fail() { printf 'FAIL  %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }

printf 'AutoPie Android/Termux compatibility doctor\n'
printf '%s\n' '------------------------------------------'

ARCH="$(uname -m 2>/dev/null || true)"
case "$ARCH" in
  aarch64|arm64)
    pass "CPU architecture: $ARCH (supported)"
    ;;
  *)
    fail "CPU architecture: ${ARCH:-unknown}. This AutoPie release is aarch64/arm64-v8a only."
    ;;
esac

SDK="$(getprop ro.build.version.sdk 2>/dev/null || true)"
RELEASE="$(getprop ro.build.version.release 2>/dev/null || true)"
if [[ "$SDK" =~ ^[0-9]+$ ]]; then
  if (( SDK >= 27 )); then
    pass "Android: ${RELEASE:-unknown} / API $SDK (meets AutoPie minSdk 27)"
  else
    fail "Android API $SDK is below AutoPie minSdk 27."
  fi

  if (( SDK == 34 || SDK == 35 )); then
    pass "AutoPie targetSdk 28 is above the Android 14/15 sideload minimum target API."
  fi
else
  warn "Could not read Android API level with getprop."
fi

if [[ -n "${PREFIX:-}" && "$PREFIX" == *"/com.termux/"* ]]; then
  pass "Termux environment detected: $PREFIX"
else
  warn "This does not look like the standard Termux environment. PREFIX=${PREFIX:-unset}"
fi

for tool in curl sha256sum termux-open; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "Install tool available: $tool"
  else
    fail "Missing install tool: $tool"
  fi
done

if command -v python3 >/dev/null 2>&1; then
  pass "Optional development tool available: python3"
else
  warn "python3 is not installed in the host Termux session. This does not block APK installation."
fi

HOME_AVAIL_KB="$(df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {print $4}' || true)"
if [[ "$HOME_AVAIL_KB" =~ ^[0-9]+$ ]]; then
  if (( HOME_AVAIL_KB >= 524288 )); then
    pass "Free space in Termux home: $((HOME_AVAIL_KB / 1024)) MiB"
  else
    warn "Low free space in Termux home: $((HOME_AVAIL_KB / 1024)) MiB. Keep at least ~500 MiB free for download/install staging."
  fi
fi

PACKAGE_PATH=""
PACKAGE_CHECK=""

if command -v rish >/dev/null 2>&1; then
  PACKAGE_PATH="$(rish -c 'pm path com.autopi' 2>/dev/null | head -n 1 || true)"
  PACKAGE_CHECK="rish"
elif command -v pm >/dev/null 2>&1; then
  PACKAGE_PATH="$(pm path com.autopi 2>/dev/null | head -n 1 || true)"
  PACKAGE_CHECK="pm"
fi

if [[ "$PACKAGE_PATH" == package:* ]]; then
  pass "AutoPie installed ($PACKAGE_CHECK): $PACKAGE_PATH"
else
  if [[ -n "$PACKAGE_CHECK" ]]; then
    pass "AutoPie is not currently detected via $PACKAGE_CHECK."
  else
    warn "Could not check whether AutoPie is installed: neither rish nor pm is usable."
  fi
fi

printf '%s\n' '------------------------------------------'
printf 'Result: %d failure(s), %d warning(s)\n' "$FAILURES" "$WARNINGS"

if (( FAILURES > 0 )); then
  exit 1
fi
