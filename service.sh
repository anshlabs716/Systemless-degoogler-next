#!/system/bin/sh

# Minimal boot-time service: ONLY grant runtime permissions to the 8
# bundled privileged apps. All APK installs happen in customize.sh (once
# at module install), never at boot. This avoids any pm/dumpsys hangs
# that could deadlock the boot process.
MODDIR=${0%/*}
MODID=$(sed -n 's/^id=//p' "$MODDIR/module.prop" | head -n 1)
[ -n "$MODID" ] || MODID=systemless-degoogler
LOG="/data/adb/modules/$MODID/log.txt"

mkdir -p "${LOG%/*}"

# Rotate log (64 KiB max, keep last 16 KiB)
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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Boot permission grant pass started"

# Wait for boot to settle (package manager fully ready)
waited=0
while [ "$(getprop sys.boot_completed)" != 1 ] && [ "$waited" -lt 300 ]; do
  sleep 2
  waited=$((waited + 2))
done
[ "$(getprop sys.boot_completed)" = 1 ] || { echo "[$(date)] Boot wait timeout"; exit 0; }
sleep 5  # extra settle time

# Grant runtime permissions to bundled apps — fire-and-forget, every call
# hard-timeboxed so nothing can block.
#
# NOTE: enumerate requested permissions with `dumpsys package <pkg>` —
# `pm list permissions -g <arg>` takes a PERMISSION GROUP name, not a
# package, and silently returned nothing (grants became a no-op).
# dumpsys lists each requested dangerous permission as
# "android.permission.X: granted=false|true"; only those are grantable.
GRANTED=0
grant_pkg() {
  P=$1
  timeout 2 pm path "$P" >/dev/null 2>&1 || return 0
  PERMS=$(timeout 5 dumpsys package "$P" 2>/dev/null \
    | grep -oE 'android\.permission\.[A-Za-z0-9_]+: granted=' \
    | sed 's/: granted=$//' | sort -u)
  [ -z "$PERMS" ] && return 0
  for M in $PERMS; do
    timeout 2 pm grant "$P" "$M" >/dev/null 2>&1 && GRANTED=$((GRANTED + 1))
  done
}

# 8 privileged apps
PRIV_PKGS="com.android.contacts com.android.deskclock com.android.dialer \
com.android.messaging org.lineageos.etar org.lineageos.recorder com.android.webview \
org.fossify.filemanager"
for P in $PRIV_PKGS; do grant_pkg "$P"; done

# Every bundled regular app from pkgs/ too — no permission dialogs on
# first launch for any of them.
AAPT="$MODDIR/aapt"
[ -x "$AAPT" ] || AAPT=""
for APK in "$MODDIR"/pkgs/*.apk; do
  [ -f "$APK" ] || continue
  [ -n "$AAPT" ] || break
  P=$("$AAPT" dump badging "$APK" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  [ -n "$P" ] && grant_pkg "$P"
done

# Default-app roles: messaging is the ONLY SMS app but Android still nags
# "change SMS app to send messages" until the SMS role holder is set.
# Same for the dialer.
timeout 3 cmd role add-role-holder android.app.role.SMS com.android.messaging --user 0 >/dev/null 2>&1
timeout 3 cmd role add-role-holder android.app.role.DIALER com.android.dialer --user 0 >/dev/null 2>&1
timeout 3 cmd role add-role-holder android.app.role.CALL_SCREENING com.android.dialer --user 0 >/dev/null 2>&1

# Fossify Files: MANAGE_EXTERNAL_STORAGE is an appop, not a runtime perm
timeout 2 appops set org.fossify.filemanager MANAGE_EXTERNAL_STORAGE allow >/dev/null 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Runtime permissions granted: $GRANTED new"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Boot permission grant pass finished"

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
