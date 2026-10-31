#!/usr/bin/env bash
# Exercises the real volume-key logic from customize.sh with a mocked getevent.
set -u

CS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/customize.sh"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

extract() {
  awk "/^$1\(\) \{/,/^\}/" "$CS"
}

ui_print() { :; }
timeout() {
  local duration=$1
  shift
  [ "$duration" = 0 ] && return 0
  [ "${VOLUME_DELAY:-0}" = 0 ] || /bin/sleep "$VOLUME_DELAY"
  [ -z "${VOLUME_EVENT:-}" ] || printf '%s\n' "$VOLUME_EVENT"
}

eval "$(extract detect_vol_key)"
eval "$(extract choose)"

fail=0
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }
check_rc() {
  expected=$1
  description=$2
  shift 2
  "$@"
  actual=$?
  if [ "$actual" = "$expected" ]; then ok "$description"
  else bad "$description (got $actual, expected $expected)"; fi
}

VOLUME_EVENT='EV_KEY KEY_VOLUMEUP DOWN'
VOLUME_DELAY=0
check_rc 0 "Volume Up is detected" detect_vol_key

VOLUME_EVENT='EV_KEY KEY_VOLUMEDOWN DOWN'
check_rc 1 "Volume Down is detected" detect_vol_key

VOLUME_EVENT='EV_KEY KEY_VOLUMEUP DOWN'
VOLUME_DELAY=0.7
check_rc 0 "a key arriving after the initial check is detected" detect_vol_key

VOLUME_EVENT='EV_ABS ABS_MT_POSITION_X 0035'
VOLUME_DELAY=0
check_rc 2 "unrelated input is not treated as a volume key" detect_vol_key

VOLUME_EVENT=
INTERACTIVE=true
check_rc 2 "no key returns the bounded automatic-profile result" choose 1
[ "$INTERACTIVE" = false ] && ok "no key disables further prompts" || bad "no key left prompts enabled"

VOLUME_EVENT='EV_KEY KEY_VOLUMEDOWN DOWN'
INTERACTIVE=true
check_rc 1 "selection works without requiring a terminal stdin" choose 1

echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
