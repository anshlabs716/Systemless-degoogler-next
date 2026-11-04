#!/system/bin/sh
# Magisk and KernelSU run this when the module is REMOVED.
#
# The bundled privileged apps (Dialer, Contacts, Messaging, DeskClock, Etar,
# Recorder, WebView, Fossify Files) live inside the module, so removing the
# module would normally make them vanish with it. Instead each one is
# migrated here to a regular user app: it stays installed after removal and
# becomes normally uninstallable from Settings like any other app.
#
# Order matters. A `pm install` for a package whose system copy is still
# mounted just re-attaches to the system package, and that dies with the
# module on the next reboot. So the module's mounts are dropped first, the
# package is fully removed, and only then is the staged APK installed as a
# plain /data/app package.

MODDIR=${0%/*}
STAGE=/data/local/tmp/sdrn-migrate
LOG=$STAGE/migrate.log

rm -rf "$STAGE"
mkdir -p "$STAGE" || exit 0
echo "[$(date)] module removal migration started" > "$LOG"

# 1. Stage every bundled system APK while the module is still present.
for APK in "$MODDIR"/system/priv-app/*/*.apk "$MODDIR"/system/app/*/*.apk; do
  [ -f "$APK" ] || continue
  DIRNAME=$(basename "$(dirname "$APK")")
  cp -f "$APK" "$STAGE/${DIRNAME}_$(basename "$APK")" 2>>"$LOG"
done

# 2. Drop this module's mounts for those folders so the package manager sees
#    the real system state. Both the directory mount and per-file binds are
#    undone; apps this module added (no stock folder underneath) only have
#    the file bind.
for DIR in "$MODDIR"/system/priv-app/* "$MODDIR"/system/app/*; do
  [ -d "$DIR" ] || continue
  NAME=$(basename "$DIR")
  for BASE in /system/priv-app /system/app; do
    TARGET="$BASE/$NAME"
    i=0
    while [ "$i" -lt 5 ]; do
      umount "$TARGET" 2>/dev/null || break
      i=$((i + 1))
    done
    for F in "$TARGET"/*.apk; do
      [ -e "$F" ] || continue
      j=0
      while [ "$j" -lt 5 ]; do
        umount "$F" 2>/dev/null || break
        j=$((j + 1))
      done
    done
  done
done

# 3. Reinstall each staged APK as a plain user app.
AAPT="$MODDIR/aapt"
for APK in "$STAGE"/*_*.apk; do
  [ -f "$APK" ] || continue

  PKG=""
  if [ -x "$AAPT" ]; then
    PKG=$("$AAPT" dump badging "$APK" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  fi
  if [ -z "$PKG" ]; then
    echo "SKIP $(basename "$APK"): package name unreadable" >> "$LOG"
    continue
  fi

  # Fully remove any remaining system-package state first.
  pm uninstall --user 0 "$PKG" >/dev/null 2>&1

  if pm path "$PKG" >/dev/null 2>&1; then
    # A system copy is still mounted; installing now would re-attach to it
    # and the app would disappear on the next reboot anyway.
    echo "SKIP $PKG: system copy still visible after umount" >> "$LOG"
    continue
  fi

  if pm install -r "$APK" >>"$LOG" 2>&1; then
    echo "MIGRATED $PKG -> normal user app" >> "$LOG"
  else
    echo "FAILED $PKG" >> "$LOG"
  fi
done

echo "[$(date)] migration finished" >> "$LOG"
# Leave the staged APKs and log behind only on failure; clean up on success.
grep -q FAILED "$LOG" || rm -rf "$STAGE"
exit 0
