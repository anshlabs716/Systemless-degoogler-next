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
  printf '%s %s\n' "$duration" "$*" >> "$TMPDIR/getevent-calls"
  [ "$duration" = 0 ] && return 0
  [ "${VOLUME_DELAY:-0}" = 0 ] || /bin/sleep "$VOLUME_DELAY"
  case "${VOLUME_EVENT_PHASE:-any}:$duration" in
    any:*|probe:1|listener:8)
      [ -z "${VOLUME_EVENT:-}" ] || printf '%s\n' "$VOLUME_EVENT" ;;
  esac
}

eval "$(extract find_volume_device)"
eval "$(extract recovery_install)"
eval "$(extract detect_vol_key)"
eval "$(extract choose)"
VOL_DEV=/dev/input/event3

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

BOOTMODE=true
OUTFD=1
if recovery_install; then bad "Magisk boot-mode install must not prompt"; else ok "Magisk boot-mode install skips volume prompts"; fi
BOOTMODE=false
unset OUTFD
if recovery_install; then bad "manager install without recovery output must not prompt"; else ok "manager install without recovery output skips prompts"; fi
OUTFD=1
if recovery_install; then ok "recovery install with OUTFD can prompt"; else bad "recovery install was not recognized"; fi

cat > "$TMPDIR/input-devices" <<'EOF'
add device 1: /dev/input/event0
  name: "touchscreen"
  KEY (0001): KEY_POWER
add device 2: /dev/input/event3
  name: "volume keys"
  KEY (0001): 0072 0073 0074
EOF
[ "$(find_volume_device "$TMPDIR/input-devices")" = /dev/input/event3 ] \
  && ok "volume device discovery selects the device advertising KEY_VOLUMEUP" \
  || bad "volume device discovery selected the wrong device"

VOLUME_EVENT='EV_KEY KEY_VOLUMEUP DOWN'
VOLUME_DELAY=0
: > "$TMPDIR/getevent-calls"
check_rc 0 "Volume Up is detected" detect_vol_key
[ "$(wc -l < "$TMPDIR/getevent-calls")" -eq 1 ] && ok "queued key is detected without starting another listener" || bad "queued key started an unexpected listener"

VOLUME_EVENT='EV_KEY KEY_VOLUMEDOWN DOWN'
VOLUME_DELAY=0
: > "$TMPDIR/getevent-calls"
check_rc 1 "Volume Down is detected" detect_vol_key

VOLUME_EVENT='EV_KEY KEY_VOLUMEUP DOWN'
VOLUME_EVENT_PHASE=listener
VOLUME_DELAY=0
: > "$TMPDIR/getevent-calls"
check_rc 0 "a key arriving in the single listener window is detected" detect_vol_key
unset VOLUME_EVENT_PHASE

VOLUME_EVENT='EV_ABS ABS_MT_POSITION_X 0035'
VOLUME_DELAY=0
: > "$TMPDIR/getevent-calls"
check_rc 2 "unrelated input is not treated as a volume key" detect_vol_key

VOLUME_EVENT=
INTERACTIVE=true
CUSTOMIZE_ABORTED=false
VOLUME_DELAY=0
: > "$TMPDIR/getevent-calls"
check_rc 2 "no key returns the bounded automatic-profile result" choose
[ "$INTERACTIVE" = false ] && ok "no key disables further prompts" || bad "no key left prompts enabled"
[ "$CUSTOMIZE_ABORTED" = true ] && ok "no key aborts optional per-app removals" || bad "no key did not abort optional removals"
[ "$(wc -l < "$TMPDIR/getevent-calls")" -eq 3 ] && ok "no-key path uses one probe, one flush, and one listener" || bad "no-key path retried detection"
[ "$(tail -n 1 "$TMPDIR/getevent-calls" | awk '{print $1}')" = 8 ] \
  && ok "fresh-key listener has one 8-second timeout" \
  || bad "fresh-key listener timeout is not 8 seconds"
[ "$(grep -vc '/dev/input/event3$' "$TMPDIR/getevent-calls")" -eq 0 ] \
  && ok "every getevent read targets the volume-key device" \
  || bad "a getevent read was not targeted to the volume-key device"

VOLUME_EVENT='EV_KEY KEY_VOLUMEDOWN DOWN'
INTERACTIVE=true
check_rc 1 "selection works without requiring a terminal stdin" choose

echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
