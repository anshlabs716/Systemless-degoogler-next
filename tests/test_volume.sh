#!/usr/bin/env bash
# Exercises the real volume-key logic from customize.sh under mocked command
# environments. Proves the installer can never block forever waiting for input
# and that every getevent output shape is classified correctly.
set -u

CS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/customize.sh"

# Pull the real function definitions out of customize.sh (not a copy).
extract() { awk "/^$1\(\) \{/,/^\}/" "$CS"; }

fail=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

# ui_print is stubbed to append to a log so assertions can grep messages.
TMPDIR=$(mktemp -d)
UILOG="$TMPDIR/uiprint.log"
ui_print() { printf '%s\n' "$*" >> "$UILOG"; }
: > "$UILOG"
# customize.sh sets these at the top; the test must mirror that or `set -u`
# aborts when the extracted functions reference them.
VOL_DEV=""

# Load the functions under test once.
eval "$(extract classify_event)"
eval "$(extract detect_vol_key)"
eval "$(extract choose)"
eval "$(extract input_capability_ok)"

# classify_event <label> <expected-rc> -- feed a line via a temp file.
cls() {
  local label=$1 want=$2 line=$3 got
  printf '%s\n' "$line" > "$TMPDIR/ev"
  classify_event "$TMPDIR/ev"; got=$?
  [ "$got" = "$want" ] && ok "$label" || bad "$label (rc=$got want=$want)"
}

echo "=== classify_event: every getevent output shape ==="
cls "labelled Volume Up DOWN -> 0"            0 "/dev/input/event4: EV_KEY  KEY_VOLUMEUP     DOWN"
cls "labelled Volume Down DOWN -> 1"          1 "/dev/input/event4: EV_KEY  KEY_VOLUMEDOWN   DOWN"
cls "hex keycode 0073 press -> 0"             0 "/dev/input/event4: EV_KEY  00000073        00000001"
cls "hex keycode 0072 press -> 1"             1 "/dev/input/event4: EV_KEY  00000072        00000001"
cls "raw EV_KEY 00000073 (no value) -> 0"     0 "EV_KEY 00000073"
cls "raw EV_KEY 00000072 (no value) -> 1"     1 "EV_KEY 00000072"
cls "unrelated ABS event -> 2"                2 "/dev/input/event2: EV_ABS ABS_MT_POSITION_X  0035"
cls "empty line -> 2"                         2 ""
cls "keyup (value 0) hex -> 2"                2 "/dev/input/event4: EV_KEY  00000073        00000000"

echo
echo "=== choose(): bounded, never hangs, prints Try again ==="
# Case A: no events -> returns 2, bounded, and re-asks.
(
  timeout() { :; }                 # produce no output at all
  export -f timeout 2>/dev/null || true
  start=$(date +%s)
  choose 1 2 > "$TMPDIR/a.out" 2>&1
  echo "$? $(( $(date +%s) - start ))" > "$TMPDIR/a"
)
read -r rcA elapsedA < "$TMPDIR/a"
[ "$rcA" = "2" ] && ok "A: no events -> returns 2 (give-up)" || bad "A: rc=$rcA want 2"
[ "$elapsedA" -le 5 ] && ok "A: terminated in ${elapsedA}s (no infinite hang)" || bad "A: took ${elapsedA}s"
grep -q "Try again" "$UILOG" && ok "A: prints 'Try again' on timeout" || bad "A: no 'Try again' message"

# Case B: Volume Up -> 0
(
  timeout() { printf 'EV_KEY KEY_VOLUMEUP 00000001\n'; }
  export -f timeout 2>/dev/null || true
  choose 1 1 >/dev/null 2>&1; echo $? > "$TMPDIR/b"
)
read -r rcB < "$TMPDIR/b"
[ "$rcB" = "0" ] && ok "B: Volume Up -> 0" || bad "B: rc=$rcB want 0"

# Case C: Volume Down -> 1
(
  timeout() { printf 'EV_KEY KEY_VOLUMEDOWN 00000001\n'; }
  export -f timeout 2>/dev/null || true
  choose 1 1 >/dev/null 2>&1; echo $? > "$TMPDIR/c"
)
read -r rcC < "$TMPDIR/c"
[ "$rcC" = "1" ] && ok "C: Volume Down -> 1" || bad "C: rc=$rcC want 1"

# Case D: hex form -> 0 (the shape that used to fail)
(
  timeout() { printf 'EV_KEY 00000073 00000001\n'; }
  export -f timeout 2>/dev/null || true
  choose 1 1 >/dev/null 2>&1; echo $? > "$TMPDIR/d"
)
read -r rcD < "$TMPDIR/d"
[ "$rcD" = "0" ] && ok "D: hex volume up -> 0" || bad "D: rc=$rcD want 0"

# Case E: unrelated input -> 2, no false positive
(
  timeout() { printf 'EV_ABS ABS_MT_POSITION_X 0035\n'; }
  export -f timeout 2>/dev/null || true
  choose 1 1 >/dev/null 2>&1; echo $? > "$TMPDIR/e"
)
read -r rcE < "$TMPDIR/e"
[ "$rcE" = "2" ] && ok "E: unrelated event -> 2 (no false positive)" || bad "E: rc=$rcE want 2"

echo
echo "=== capability probe ==="
# Case F: missing toolchain -> denied
(
  eval "$(extract input_capability_ok)"
  PATH=/dev/null
  command() { return 1; }
  export -f command 2>/dev/null || true
  input_capability_ok >/dev/null 2>&1; echo $? > "$TMPDIR/f"
)
read -r rcF < "$TMPDIR/f"
[ "$rcF" = "1" ] && ok "F: missing toolchain -> capability denied" || bad "F: rc=$rcF want 1"

# Case G: no BOOTMODE/OUTFD gate -- capability is about the toolchain only.
# On this host /system/bin/getevent is absent, so the probe must fail regardless
# of any BOOTMODE/OUTFD env. That is exactly the manager-install fix.
(
  unset BOOTMODE OUTFD 2>/dev/null || true
  eval "$(extract input_capability_ok)"
  input_capability_ok >/dev/null 2>&1; echo $? > "$TMPDIR/g"
)
read -r rcG < "$TMPDIR/g"
[ "$rcG" = "1" ] && ok "G: no /system/bin/getevent -> not interactive (no TTY/BOOTMODE gate)" || bad "G: rc=$rcG want 1"

rm -rf "$TMPDIR"
echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
