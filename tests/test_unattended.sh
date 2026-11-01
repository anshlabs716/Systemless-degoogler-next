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
if code | grep -q 'bloat_packagelist' && code | grep -A3 'debloat_list"' | grep -q 'process_package'; then
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

echo "=== 8. bundled pkgs still installed (service.sh) ==="
if grep -q 'pkgs/\*\.apk' "$ROOT/service.sh"; then
  ok "service.sh installs pkgs/*.apk"
else
  bad "service.sh does not install pkgs/*.apk"
fi

echo "=== 9. no 'read' prompt / abort-on-no-input ==="
if code | grep -qE '^[[:space:]]*read[[:space:]]'; then
  bad "shell 'read' prompt present"
else
  ok "no shell read prompt"
fi

echo "=== 10. Bixby + OEM protections intact ==="
for pat in 'bixby' 'essential Samsung service' 'essential Xiaomi service'; do
  grep -qiF "$pat" "$CS" && ok "kept: $pat" || bad "missing: $pat"
done

echo
[ "$fail" = 0 ] && echo "ALL UNATTENDED-INSTALL TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
