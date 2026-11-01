#!/system/bin/sh

# Install bundled replacement APKs after Android's package manager is ready.
# System APKs are scanned by Android at boot; this pass verifies they are
# available and installs only if the package manager did not register one.
MODDIR=${0%/*}
MODID=$(sed -n 's/^id=//p' "$MODDIR/module.prop" | head -n 1)
[ -n "$MODID" ] || MODID=systemless-degoogler
LOG="/data/adb/modules/$MODID/log.txt"

mkdir -p "${LOG%/*}"

# Rotate the log so it can never grow without bound. Only the most recent
# chunk is carried forward; older history is dropped. 64 KiB is plenty to
# debug the last several boots.
LOG_MAX=65536
LOG_KEEP=16384
if [ -f "$LOG" ]; then
  LOG_SIZE=$(wc -c < "$LOG" 2>/dev/null | tr -d ' ')
  case "$LOG_SIZE" in ''|*[!0-9]*) LOG_SIZE=0 ;; esac
  if [ "$LOG_SIZE" -gt "$LOG_MAX" ]; then
    tail -c "$LOG_KEEP" "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
  fi
fi

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

INSTALLED=0
PRESENT=0
SKIPPED=0
FAILED=0

# The FOSS replacement apps ship under pkgs/ and are installed as REGULAR
# apps (via pm install), not as system apps. Only MILES lives in system/app
# and the privileged LineageOS suite in system/priv-app; both are mounted by
# the root manager and must never be pm-installed here.
for APK in "$MODDIR"/pkgs/*.apk; do
  [ -f "$APK" ] || continue
  FILE=${APK##*/}

  # These are intentionally manual-only and must never be bundled/installed.
  case "$FILE" in *microg*|*MicroG*|*aa4mg*|*AA4MG*)
    SKIPPED=$((SKIPPED + 1))
    continue ;;
  esac

  PACKAGE=$("$AAPT" dump badging "$APK" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  if [ -z "$PACKAGE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping unreadable APK $FILE (package ID unavailable)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  case "$PACKAGE" in
    com.google.android.gms|com.google.android.gsf|com.google.android.projection.gearhead)
      SKIPPED=$((SKIPPED + 1))
      continue ;;
  esac

  # Present (system or already installed) is the normal steady state and is
  # counted rather than logged line by line, so the log does not grow by
  # dozens of identical lines every boot.
  if pm path "$PACKAGE" 2>/dev/null | grep -q '^package:'; then
    PRESENT=$((PRESENT + 1))
    continue
  fi

  RESULT=$(pm install -r "$APK" 2>&1)
  STATUS=$?
  if [ "$STATUS" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Installed $PACKAGE ($FILE): $RESULT"
    INSTALLED=$((INSTALLED + 1))
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Install failed for $PACKAGE ($FILE): $RESULT"
    FAILED=$((FAILED + 1))
  fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pass finished: $INSTALLED installed, $PRESENT already present, $SKIPPED skipped, $FAILED failed"

# NOTE (v1.0.3): the launcher swap that used to live here is gone for good.
# It set Lawnchair as default home and then ran
#   pm disable-user --user 0 com.android.launcher3
# Deleting Lawnchair afterwards left the device with NO home activity at all.
# A launcher must never be disabled by this module: the stock launcher stays
# default and untouched. The Google bar, mic and Lens are cosmetic and are not
# worth bricking someone's home screen over.
#
# NOTE (v1.0.3): Futo Keyboard (org.futo.inputmethod.latin) is bundled as
# pkgs/29_futo.apk and pre-installed by customize.sh before Gboard removal.
# This ensures the device is never left keyboard-less. This service.sh pass
# may also install it if customize.sh was skipped or failed.
