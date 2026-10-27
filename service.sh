#!/system/bin/sh

# Install bundled replacement APKs after Android's package manager is ready.
# Files are processed lexically, so the two-digit prefixes define install order.
MODDIR=${0%/*}
MODID=$(sed -n 's/^id=//p' "$MODDIR/module.prop" | head -n 1)
[ -n "$MODID" ] || MODID=systemless-degoogler
LOG="/data/adb/modules/$MODID/log.txt"

mkdir -p "${LOG%/*}"
exec >>"$LOG" 2>&1
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Replacement APK install pass started"

# Wait up to five minutes for Android to finish booting.
waited=0
while [ "$(getprop sys.boot_completed)" != 1 ] && [ "$waited" -lt 300 ]; do
  sleep 2
  waited=$((waited + 2))
done
if [ "$(getprop sys.boot_completed)" != 1 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Timed out waiting for boot; will retry next boot"
  exit 0
fi

AAPT="$MODDIR/tools/aapt64"
[ -x "$AAPT" ] || AAPT="$MODDIR/tools/aapt"

for APK in "$MODDIR"/pkgs/*.apk; do
  [ -f "$APK" ] || continue
  FILE=${APK##*/}

  # These are intentionally manual-only and must never be bundled/installed.
  case "$FILE" in *microg*|*MicroG*|*aa4mg*|*AA4MG*)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping manual-only APK $FILE"
    continue ;;
  esac

  PACKAGE=$("$AAPT" dump badging "$APK" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  if [ -z "$PACKAGE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping unreadable APK $FILE (package ID unavailable)"
    continue
  fi

  case "$PACKAGE" in
    com.google.android.gms|com.google.android.gsf|com.google.android.projection.gearhead)
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping protected/manual-only package $PACKAGE ($FILE)"
      continue ;;
  esac

  if pm path "$PACKAGE" 2>/dev/null | grep -q '^package:'; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already installed; skipped $PACKAGE ($FILE)"
    continue
  fi

  RESULT=$(pm install -r "$APK" 2>&1)
  STATUS=$?
  if [ "$STATUS" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed $PACKAGE ($FILE): $RESULT"
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Install failed for $PACKAGE ($FILE): $RESULT"
  fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Replacement APK install pass finished"

# NOTE (v1.0.3): the launcher swap that used to live here is gone for good.
# It set Lawnchair as default home and then ran
#   pm disable-user --user 0 com.android.launcher3
# Deleting Lawnchair afterwards left the device with NO home activity at all.
# A launcher must never be disabled by this module: the stock launcher stays
# default and untouched. The Google bar, mic and Lens are cosmetic and are not
# worth bricking someone's home screen over.
