#!/usr/bin/env bash
# Asserts customize.sh is a fully unattended installer: no volume-key prompt,
# no getevent, no per-app question. This replaces the old choose() tests --
# choose() no longer exists because the prompt was removed entirely.
#
# Why: the prompt never changed WHAT gets removed (both answers applied the
# same list), it only decided whether to then ask about each app one by one.
# It was also fragile -- getevent reads /dev/input directly, so it behaved
# differently in a recovery (screen idle) vs the Magisk/KernelSU manager
# (screen live, ~333 touchscreen events/sec starving `getevent -c 1`), and a
# failure left the install hanging on "Waiting for a volume key...".
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CS="$ROOT/customize.sh"

fail=0
ok() { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

# Strip comment lines so prose mentioning "getevent"/"volume" can't mask code.
code() { grep -vE '^[[:space:]]*#' "$CS"; }

echo "=== 1. no getevent invocation in executable code ==="
if code | grep -q 'getevent'; then
  bad "getevent still invoked: $(code | grep 'getevent' | head -1)"
else
  ok "no getevent anywhere in code"
fi

echo "=== 2. no choose() function ==="
if grep -qE '^choose\(\)[[:space:]]*\{' "$CS"; then
  bad "choose() still defined"
else
  ok "choose() removed"
fi

echo "=== 3. no volume-key prompt text ==="
for pat in 'Waiting for a volume key' 'Volume Up: Yes' 'Volume Down: No' \
           'Choose apps one by one' 'Volume key not detected'; do
  if code | grep -qF "$pat"; then
    bad "prompt text still present: $pat"
  else
    ok "absent: $pat"
  fi
done

echo "=== 4. no per-app question ==="
if code | grep -qE 'Remove \$APP_NAME\?'; then
  bad "per-app 'Remove $APP_NAME?' question still present"
else
  ok "no per-app question"
fi

echo "=== 5. no interactive gate left behind ==="
if code | grep -qE '\bINTERACTIVE\b|\bCUSTOMIZE\b|\bVOL_WAIT\b|\bAPPLY_OPTIONAL\b|\bCUSTOMIZE_ABORTED\b'; then
  bad "stale flag referenced: $(code | grep -oE '\bINTERACTIVE\b|\bCUSTOMIZE\b|\bVOL_WAIT\b|\bAPPLY_OPTIONAL\b|\bCUSTOMIZE_ABORTED\b' | sort -u | tr '\n' ' ')"
else
  ok "no stale interactive flags"
fi

echo "=== 6. optional list is applied unconditionally ==="
if code | grep -q 'bloat_packagelist' && code | grep -A6 'debloat_list"' | grep -q 'process_package'; then
  ok "optional list walked via process_package"
else
  bad "optional list not walked"
fi
if code | grep -q 'if \[ "\$APPLY_OPTIONAL"'; then
  bad "optional list still behind an APPLY_OPTIONAL condition"
else
  ok "optional list not behind a condition"
fi

echo "=== 7. force list still applied ==="
if code | grep -q 'force_list' && code | grep -A5 'force_list"' | grep -q 'process_package'; then
  ok "force list walked via process_package"
else
  bad "force list not walked"
fi

echo "=== 8. bundled pkgs installed in customize.sh (not at boot) ==="
if grep -q 'pkgs/\*\.apk' "$ROOT/customize.sh"; then
  ok "customize.sh installs pkgs/*.apk at module install"
else
  bad "customize.sh does not install pkgs/*.apk"
fi
if grep -q 'pm install' "$ROOT/service.sh"; then
  bad "service.sh still has an install loop (boot hang risk)"
else
  ok "service.sh never pm-installs at boot (grants only)"
fi

if grep -q 'PACKAGE=\("\$AAPT"\|"\$LOOP_AAPT"\)' "$ROOT/customize.sh"; then :; fi
if grep -q 'LOOP_AAPT="\$MODPATH/aapt"' "$ROOT/customize.sh" && \
   ! grep -q 'PACKAGE=\("\$AAPT" ' "$ROOT/customize.sh"; then
  ok "install loop uses the absolute module-local aapt"
else
  bad "install loop may invoke aapt via PATH (bare \$AAPT) -> every APK silently skipped"
fi
if code | grep -qE '^[[:space:]]*read[[:space:]]'; then
  bad "shell 'read' prompt present"
else
  ok "no shell read prompt"
fi

echo "=== 9. bundle-integrity guard (truncated-download protection) ==="
if grep -q 'Bundle integrity OK' "$ROOT/customize.sh" && grep -q 'abort "Re-download the current release ZIP' "$ROOT/customize.sh"; then
  ok "aborts loudly on an incomplete bundle"
else
  bad "no bundle-integrity guard -> a truncated zip flashes silently without essentials"
fi

echo "=== 10. Bixby + OEM protections intact ==="
for pat in 'bixby' 'essential Samsung service' 'essential Xiaomi service'; do
  grep -qiF "$pat" "$CS" && ok "kept: $pat" || bad "missing: $pat"
done

echo "=== 11. masks are ACTUALLY created (the bug that let all Google apps survive) ==="
# Every release up to now collected paths into $REMOVE, printed "Systemlessly
# masked", then wrote them to .lastremove -- a file nothing reads. No mask was
# ever made, so no system app was ever removed. Magisk/KernelSU only hide an
# app when a file named `.replace` exists in the module folder.
if code | grep -q '\.replace'; then
  ok "creates .replace (magic mount mask)"
else
  bad "no .replace created -> removal is a no-op again"
fi
if code | grep -q 'mkdir -p "\$DEST"'; then
  ok "creates the destination folder first"
else
  bad "does not create the mask folder"
fi
if code | grep -q 'find "\$DEST" -name .\*\.apk'; then
  ok "guards folders holding our own APKs (any depth)"
else
  bad "no guard -> could mask our own bundled apps"
fi
if code | grep -q 'SKIPPED_SHARED'; then
  ok "never masks shared container dirs (overlay/app/priv-app)"
else
  bad "no shared-dir guard -> could mask /vendor/overlay and bootloop"
fi

echo "=== 12. updated (/data/app) Google apps are removed, not skipped ==="
# Play Store updates move Google apps into /data/app where a systemless mask
# cannot reach them. An updated system app reports BOTH its system path and
# the update, so every pm path line must be inspected: reading only the first
# let the update survive whenever the system path came first. The bundled
# replacements are asserted off these lists by tests/test_lists.sh, so
# removing every listed package is safe.
if code | grep -q '\*"/data/app/"\*'; then
  ok "matches /data/app across ALL pm path lines"
else
  bad "does not scan every pm path line"
fi
if code | grep -q "sed -n '1s/\^package://p'"; then
  bad "still reads only the first pm path line"
else
  ok "no first-line-only pm path read"
fi
if code | grep -A8 '"/data/app/"' | grep -q 'pm uninstall --user 0'; then
  ok "uninstalls listed /data/app packages"
else
  bad "no pm uninstall for /data/app packages"
fi
if code | grep -q 'Skipped updated/user-installed'; then
  bad "still skips optional updated packages"
else
  ok "no skip branch left for optional packages"
fi

echo "=== 13. runtime permissions auto-granted at boot ==="
SRV="$ROOT/service.sh"
grep -q 'pm grant' "$SRV" && ok "service.sh runs pm grant" || bad "service.sh never grants permissions"
grep -q 'PRIV_PKGS=' "$SRV" && ok "targets the bundled priv-apps" || bad "no PRIV_PKGS list"
MISSING=""
for p in com.android.deskclock org.lineageos.etar org.lineageos.recorder \
         com.android.webview org.fossify.filemanager org.fossify.phone \
         org.fossify.messages org.fossify.contacts; do
  grep -q "$p" "$SRV" || MISSING="$MISSING $p"
done
if [ -n "$MISSING" ]; then
  bad "missing from grant list:$MISSING"
else
  ok "grant list covers all 8 bundled priv-apps"
fi
grep -q 'MANAGE_EXTERNAL_STORAGE' "$SRV" && ok "Fossify Files gets All Files Access (appop)" || bad "no appops grant for Fossify Files"
grep -q 'org.fossify.messages' "$SRV" && ok "SMS default targets Fossify Messages" || bad "no Fossify Messages in service.sh"
grep -q 'sms_default_application' "$SRV" && ok "legacy default-SMS setting set at boot" || bad "no legacy sms_default_application"
grep -q 'WRITE_SMS' "$SRV" && ok "WRITE_SMS appop granted" || bad "no WRITE_SMS appop"

echo "=== 14. module removal migrates bundled apps to normal apps ==="
US="$ROOT/uninstall.sh"
[ -f "$US" ] && ok "uninstall.sh exists" || bad "missing uninstall.sh"
grep -q 'pm install' "$US" && ok "reinstalls each app as a user app" || bad "no pm install migration"
grep -q 'umount' "$US" && ok "drops module mounts before installing" || bad "no umount step"
grep -q 'uninstall.sh' "$ROOT/build.sh" && ok "build ships uninstall.sh in both zips" || bad "uninstall.sh not in zip lists"
