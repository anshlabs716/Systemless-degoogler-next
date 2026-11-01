#!/usr/bin/env bash
# Exercises the real choose() from customize.sh under a mocked getevent.
# Asserts:
#   * returns 0 on Volume Up, 1 on Volume Down
#   * retries with "Try again" until a key arrives (never gives up silently)
#   * passes NO device argument to getevent
#   * does NOT use `-c 1`  <- the touch-flood starvation bug (measured 0.05s)
#   * touchscreen noise cannot end the wait early
set -u

CS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/customize.sh"
extract() { awk "/^$1\(\) \{/,/^}/" "$CS"; }

fail=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

TMPDIR=$(mktemp -d)
UILOG="$TMPDIR/uiprint.log"
ui_print() { printf '%s\n' "$*" >> "$UILOG"; }

eval "$(extract choose)"

# choose() now runs:  timeout "$delay" getevent -l | grep -m1 -E <pat> > events
# Mock getevent through `timeout`; the pipe's grep is the REAL one, so this
# exercises the actual filter.
SCRIPT="$TMPDIR/script"   # each line = one call's stdout ("" = simulated timeout)
CALLS="$TMPDIR/calls"     # one line per call: the raw argv

reset() { : > "$SCRIPT"; : > "$CALLS"; : > "$UILOG"; }
add()   { printf '%s\n' "$1" >> "$SCRIPT"; }

timeout() {
  printf '%s\n' "$*" >> "$CALLS"
  if [ -s "$SCRIPT" ]; then
    line=$(head -n1 "$SCRIPT")
    sed -i '1d' "$SCRIPT"
    [ -n "$line" ] && printf '%s\n' "$line"
  fi
  # no line left -> emit nothing (simulated timeout)
}
export -f timeout 2>/dev/null || true

echo "=== Case 1: Volume Up on first try -> 0 ==="
reset
add "/dev/input/event0: EV_KEY       KEY_VOLUMEUP            DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 0 ] && ok "Volume Up -> 0" || bad "Volume Up rc=$? want 0"

echo "=== Case 2: Volume Down on first try -> 1 ==="
reset
add "/dev/input/event0: EV_KEY       KEY_VOLUMEDOWN          DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 1 ] && ok "Volume Down -> 1" || bad "Volume Down rc=$? want 1"

echo "=== Case 3: timeout, then Volume Up -> retries then 0 ==="
reset
add ""                                                   # attempt 1: no key
add "/dev/input/event0: EV_KEY       KEY_VOLUMEUP        DOWN"
choose 1 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && ok "retry then Volume Up -> 0" || bad "rc=$rc want 0"
grep -q "Try again" "$UILOG" && ok "printed 'Try again' on timeout" || bad "no 'Try again'"
n=$(wc -l < "$CALLS" | tr -d ' ')
[ "$n" -ge 2 ] && ok "getevent called $n times (kept looping)" || bad "only $n call(s)"

echo "=== Case 4: NO device argument (reads all devices) ==="
reset
add "/dev/input/event0: EV_KEY       KEY_VOLUMEUP        DOWN"
choose 1 >/dev/null 2>&1
args=$(head -n1 "$CALLS")
if printf '%s' "$args" | grep -q '/dev/input/'; then
  bad "device path passed to getevent: $args"
else
  ok "no device argument (listens to all devices)"
fi
printf '%s' "$args" | grep -qE -- '-l([[:space:]]|$)' \
  && ok "invokes getevent -l (streaming, not single-event)" || bad "flags wrong: $args"

echo "=== Case 5 (THE STARVATION FIX): no -c 1 ==="
# `getevent -lqc 1` exits on the FIRST event of any device. Measured on a live
# Pixel 6 Pro: it returned in 0.05s with BTN_TOUCH, so the 10s wait never
# waited and a volume press was starved behind ~333 touch events/sec.
if printf '%s' "$args" | grep -qE -- '-[^ ]*c[^ ]* [0-9]|-c[0-9]'; then
  bad "uses -c N (single-event mode) -> touch flood ends wait early: $args"
else
  ok "no -c 1 -> wait is not ended by touch noise"
fi

echo "=== Case 6: touch noise does NOT satisfy choose (filter works) ==="
reset
add "/dev/input/event3: EV_KEY       BTN_TOUCH            DOWN"
add "/dev/input/event3: EV_ABS       ABS_MT_POSITION_X    0000057d"
add "/dev/input/event0: EV_KEY       KEY_VOLUMEDOWN          DOWN"
choose 1 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 1 ] && ok "ignored 2 touch events, then Volume Down -> 1" || bad "rc=$? want 1"
grep -q "Try again" "$UILOG" && ok "retried after non-key events" || bad "no retry"

echo "=== Case 7: BTN_TOUCH must not be mistaken for a volume key ==="
reset
add "/dev/input/event3: EV_KEY       BTN_TOUCH            DOWN"
add "/dev/input/event0: EV_KEY       KEY_POWER            DOWN"
add "/dev/input/event0: EV_KEY       KEY_VOLUMEUP            DOWN"
choose 1 >/dev/null 2>&1
[ $? -eq 0 ] && ok "touch+power ignored, Volume Up -> 0" || bad "rc=$? want 0"

rm -rf "$TMPDIR"
echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
