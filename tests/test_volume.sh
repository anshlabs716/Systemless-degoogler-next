#!/usr/bin/env bash
# Exercises the real choose() from customize.sh (ported from the proven-working
# v1.0.2) under a mocked getevent. Asserts:
#   * returns 0 on Volume Up, 1 on Volume Down
#   * retries with "Try again" until a key arrives (never gives up silently)
#   * passes NO device argument to getevent  <- the v1.0.3 regression
set -u

CS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/customize.sh"
extract() { awk "/^$1\(\) \{/,/^\}/" "$CS"; }

fail=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

TMPDIR=$(mktemp -d)
UILOG="$TMPDIR/uiprint.log"
ui_print() { printf '%s\n' "$*" >> "$UILOG"; }

eval "$(extract choose)"

# Mock getevent via `timeout`. choose() invokes:
#   timeout "$delay" /system/bin/getevent -lqc 1 >"$TMPDIR/events" 2>&1
# The mock ignores the delay, records its argv, and emits scripted output.
SCRIPT="$TMPDIR/script"     # each line = one call's stdout ("" = timeout)
CALLS="$TMPDIR/calls"       # one line per call: the raw argv

reset() { : > "$SCRIPT"; : > "$CALLS"; : > "$UILOG"; }
add()   { printf '%s\n' "$1" >> "$SCRIPT"; }

timeout() {
  printf '%s\n' "$*" >> "$CALLS"
  if [ -s "$SCRIPT" ]; then
    head -n1 "$SCRIPT" | sed '1d' >/dev/null 2>&1 || true
    line=$(head -n1 "$SCRIPT")
    sed -i '1d' "$SCRIPT"
    [ -n "$line" ] && printf '%s\n' "$line"
  fi
  # no line left -> emit nothing (simulated timeout)
}
export -f timeout 2>/dev/null || true

echo "=== Case 1: Volume Up on first try -> 0 ==="
reset
add "/dev/input/event0: EV_KEY  KEY_VOLUMEUP   DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 0 ] && ok "Volume Up -> 0" || bad "Volume Up rc=$? want 0"

echo "=== Case 2: Volume Down on first try -> 1 ==="
reset
add "/dev/input/event0: EV_KEY  KEY_VOLUMEDOWN DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 1 ] && ok "Volume Down -> 1" || bad "Volume Down rc=$? want 1"

echo "=== Case 3: timeout, then Volume Up -> retries then 0 ==="
reset
add ""                                          # attempt 1: no key
add "/dev/input/event0: EV_KEY  KEY_VOLUMEUP DOWN"  # attempt 2: key
choose 1 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "retry then Volume Up -> 0" || bad "rc=$rc want 0"
grep -q "Try again" "$UILOG" && ok "printed 'Try again' on timeout" || bad "no 'Try again'"
n=$(wc -l < "$CALLS" | tr -d ' ')
[ "$n" -ge 2 ] && ok "getevent called $n times (kept looping)" || bad "only $n call(s)"

echo "=== Case 4 (THE FIX): getevent gets NO device argument ==="
reset
add "/dev/input/event0: EV_KEY  KEY_VOLUMEUP DOWN"
choose 1 >/dev/null 2>&1
# argv looks like: 10 /system/bin/getevent -lqc 1    (no /dev/input/... at end)
args=$(head -n1 "$CALLS")
if printf '%s' "$args" | grep -q '/dev/input/'; then
  bad "device path passed to getevent: $args"
else
  ok "no device argument (reads all devices, like v1.0.2)"
fi
printf '%s' "$args" | grep -q -- '-lqc 1' \
  && ok "invokes getevent -lqc 1 (flags intact)" || bad "flags wrong: $args"

echo "=== Case 5: unrelated event -> keeps looping, not a false match ==="
reset
add "/dev/input/event3: EV_ABS  ABS_MT_POSITION_X 0000057d"
add "/dev/input/event0: EV_KEY  KEY_VOLUMEDOWN DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 1 ] && ok "ignored touch, then Volume Down -> 1" || bad "rc=$? want 1"
grep -q "Try again" "$UILOG" && ok "retried after non-key event" || bad "no retry"

rm -rf "$TMPDIR"
echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
