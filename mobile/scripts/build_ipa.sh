#!/bin/bash
#
# Builds a release IPA for TestFlight / App Store, safely.
#
# Folds in the two things that otherwise silently produce a rejected upload on
# this machine:
#
#   1. macOS 26 stamps disallowed xattrs on build output, which fail codesign.
#      We prepend ~/.edulinky-bin (a codesign wrapper that passes
#      --strip-disallowed-xattrs) to PATH for the build only — no global change,
#      so a second app/team on this Mac is untouched. See
#      scripts/add_google_url_scheme.sh's sibling note / the codesign wrapper.
#
#   2. `flutter run` on a Simulator populates build/native_assets/ with a
#      *simulator* build of objective_c.framework (from path_provider_foundation),
#      and `flutter build ipa` reuses it — Apple then rejects the arm64 slice as
#      "unsupported platform (simulator)". A hard clean forces a device rebuild,
#      and we VERIFY the platform before declaring success so a bad binary can
#      never reach Transporter.
#
# Usage:
#   bash scripts/build_ipa.sh
#
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DIR"

WRAPPER="$HOME/.edulinky-bin"
DEFINES="dart_defines.json"

# --- preflight ---------------------------------------------------------------
if [ ! -x "$WRAPPER/codesign" ]; then
  echo "✗ codesign wrapper missing at $WRAPPER/codesign"
  echo "  Recreate it (no sudo):"
  echo "    mkdir -p ~/.edulinky-bin && cat > ~/.edulinky-bin/codesign <<'EOF'"
  echo "    #!/bin/bash"
  echo "    for arg in \"\$@\"; do"
  echo "      if [[ \"\$arg\" == \"--sign\" || \"\$arg\" == \"-s\" ]]; then"
  echo "        exec /usr/bin/codesign --strip-disallowed-xattrs \"\$@\""
  echo "      fi"
  echo "    done"
  echo "    exec /usr/bin/codesign \"\$@\""
  echo "    EOF"
  echo "    chmod +x ~/.edulinky-bin/codesign"
  exit 1
fi
if [ ! -f "$DEFINES" ]; then
  echo "✗ $DEFINES not found (holds the RevenueCat SDK keys). Create it first."
  exit 1
fi

# --- clean (mandatory — see note 2) ------------------------------------------
echo "▸ Cleaning…"
flutter clean >/dev/null
rm -rf build

# --- build -------------------------------------------------------------------
echo "▸ Building release IPA…"
PATH="$WRAPPER:$PATH" flutter build ipa --release --dart-define-from-file="$DEFINES"

# --- verify the native-assets framework targets the device -------------------
# Apple LC_BUILD_VERSION platform: 2 = iOS (device), 7 = iOS Simulator.
IPA="$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1 || true)"
if [ -z "$IPA" ]; then
  echo "✗ No IPA produced."
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
unzip -q "$IPA" -d "$WORK"
FW="$WORK/Payload/Runner.app/Frameworks/objective_c.framework/objective_c"

if [ -f "$FW" ]; then
  PLATFORM="$(otool -l "$FW" | awk '/LC_BUILD_VERSION/{f=1} f&&/platform/{print $2; exit}')"
  case "$PLATFORM" in
    2) echo "✓ objective_c.framework: iOS device (platform 2)";;
    7) echo "✗ objective_c.framework is a SIMULATOR build (platform 7)."
       echo "  Do NOT upload. Re-run this script (the clean should fix it)."
       exit 1;;
    *) echo "⚠ objective_c.framework platform is '$PLATFORM' (expected 2). Inspect before uploading.";;
  esac
else
  echo "• objective_c.framework not embedded (statically linked) — nothing to verify."
fi

echo
echo "✓ IPA ready: $IPA"
echo "  Upload with Transporter, or:"
echo "  xcrun altool --upload-app --type ios -f \"$IPA\" --apiKey <KEY> --apiIssuer <ISSUER>"
