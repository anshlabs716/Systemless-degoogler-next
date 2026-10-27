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

# --- Kill the Google bar, mic and Lens -------------------------------------
# They are drawn by the stock launcher (com.android.launcher3) itself, not by
# the Google app, so uninstalling Google never removes them. The fix is to make
# a launcher that does not render them the default home, then retire the stock
# one. Only done when the replacement is actually present, so the device is
# never left without a home screen.
LAUNCHER_APK=$(ls "$MODDIR"/pkgs/*awnchair* 2>/dev/null | head -n 1)
if [ -n "$LAUNCHER_APK" ]; then
  BADGING=$("$AAPT" dump badging "$LAUNCHER_APK" 2>/dev/null)
  LP=$(printf '%s\n' "$BADGING" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  ACT=$(printf '%s\n' "$BADGING" | sed -n "s/^launchable-activity: name='\([^']*\)'.*/\1/p" | head -n 1)

  if [ -n "$LP" ] && [ -n "$ACT" ] && pm path "$LP" >/dev/null 2>&1; then
    if cmd package set-home-activity --user 0 "$LP/$ACT" >/dev/null 2>&1 ||
       cmd package set-home-activity "$LP/$ACT" >/dev/null 2>&1; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Default home -> $LP/$ACT"
      if pm disable-user --user 0 com.android.launcher3 >/dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Retired stock launcher com.android.launcher3 (Google bar, mic and Lens gone)"
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Could not retire com.android.launcher3"
      fi
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Could not set default home to $LP/$ACT"
    fi
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Replacement launcher not installed yet; will retry next boot"
  fi
fi
