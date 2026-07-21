#!/bin/bash
# Injects the Google OAuth callback URL scheme (REVERSED_CLIENT_ID) from
# GoogleService-Info.plist into Info.plist's CFBundleURLTypes. Idempotent.
#
# Run AFTER enabling Google sign-in in the Firebase console and re-downloading
# GoogleService-Info.plist into ios/Runner/.
#
#   bash scripts/add_google_url_scheme.sh
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
GSI="$DIR/ios/Runner/GoogleService-Info.plist"
INFO="$DIR/ios/Runner/Info.plist"
PB=/usr/libexec/PlistBuddy

REVERSED=$("$PB" -c "Print :REVERSED_CLIENT_ID" "$GSI" 2>/dev/null || true)
if [ -z "$REVERSED" ]; then
  echo "✗ REVERSED_CLIENT_ID not found in GoogleService-Info.plist."
  echo "  Enable Google sign-in in Firebase Auth, then re-download the plist."
  exit 1
fi

# Create CFBundleURLTypes array if missing.
"$PB" -c "Print :CFBundleURLTypes" "$INFO" >/dev/null 2>&1 || \
  "$PB" -c "Add :CFBundleURLTypes array" "$INFO"

# Skip if the scheme is already present anywhere in the plist.
if /usr/bin/grep -q "$REVERSED" "$INFO"; then
  echo "✓ URL scheme already present — nothing to do."
  exit 0
fi

IDX=$("$PB" -c "Print :CFBundleURLTypes" "$INFO" | /usr/bin/grep -c "Dict" || true)
"$PB" -c "Add :CFBundleURLTypes:$IDX dict" "$INFO"
"$PB" -c "Add :CFBundleURLTypes:$IDX:CFBundleTypeRole string Editor" "$INFO"
"$PB" -c "Add :CFBundleURLTypes:$IDX:CFBundleURLSchemes array" "$INFO"
"$PB" -c "Add :CFBundleURLTypes:$IDX:CFBundleURLSchemes:0 string $REVERSED" "$INFO"

/usr/bin/plutil -lint "$INFO"
echo "✓ Added Google URL scheme: $REVERSED"
