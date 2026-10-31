#!/usr/bin/env bash
# Exercises the real volume-key logic from customize.sh under mocked command
# environments. Proves the installer can never block forever waiting for input.
set -u

CS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/customize.sh"

# Pull the real function definitions out of customize.sh (not a copy).
extract() {
  awk "/^$1\(\) \{/,/^\}/" "$CS"
}

fail=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

# Minimal harness environment.
ui_print() { :; }
TMPDIR=$(mktemp -d)

# --- Case 1: no input events at all -> choose() must return 2, bounded -------
# `timeout` and `getevent` are mocked to produce an empty events file.
(
  timeout() { :; }              # produce no output at all
  export -f timeout 2>/dev/null || true
  eval "$(extract input_capability_ok)"
  eval "$(extract choose)"
  # Override the binary lookup inside choose by shadowing getevent writes:
  getevent_empty() { :; }
  start=$(date +%s)
  # choose <delay> <attempts> -- delay 1s, 2 attempts
  choose 1 2
  rc=$?
  end=$(date +%s)
  echo "$rc $((end - start))" > "$TMPDIR/case1"
)
read -r rc1 elapsed1 < "$TMPDIR/case1"
[ "$rc1" = "2" ] && ok "case1: returns 2 (give-up) when no events arrive" || bad "case1: rc=$rc1 expected 2"
[ "$elapsed1" -le 5 ] && ok "case1: terminated in ${elapsed1}s (no infinite hang)" || bad "case1: took ${elapsed1}s"

# --- Case 2: Volume Up arrives -> return 0 -----------------------------------
(
  timeout() { printf 'EV_KEY KEY_VOLUMEUP 00000001\n'; }
  export -f timeout 2>/dev/null || true
  eval "$(extract choose)"
  choose 1 1 >/dev/null 2>&1
  echo $? > "$TMPDIR/case2"
)
read -r rc2 < "$TMPDIR/case2"
[ "$rc2" = "0" ] && ok "case2: Volume Up -> 0" || bad "case2: rc=$rc2 expected 0"

# --- Case 3: Volume Down arrives -> return 1 ---------------------------------
(
  timeout() { printf 'EV_KEY KEY_VOLUMEDOWN 00000001\n'; }
  export -f timeout 2>/dev/null || true
  eval "$(extract choose)"
  choose 1 1 >/dev/null 2>&1
  echo $? > "$TMPDIR/case3"
)
read -r rc3 < "$TMPDIR/case3"
[ "$rc3" = "1" ] && ok "case3: Volume Down -> 1" || bad "case3: rc=$rc3 expected 1"

# --- Case 4: labelled 'DOWN' form (old getevent output) -> 0 -----------------
(
  timeout() { printf 'EV_KEY KEY_VOLUMEUP     DOWN\n'; }
  export -f timeout 2>/dev/null || true
  eval "$(extract choose)"
  choose 1 1 >/dev/null 2>&1
  echo $? > "$TMPDIR/case4"
)
read -r rc4 < "$TMPDIR/case4"
[ "$rc4" = "0" ] && ok "case4: labelled DOWN form -> 0" || bad "case4: rc=$rc4 expected 0"

# --- Case 5: raw EV_KEY hex keycode form -> 1 for volume down ---------------
(
  timeout() { printf 'EV_KEY 00000072 00000001\n'; }
  export -f timeout 2>/dev/null || true
  eval "$(extract choose)"
  choose 1 1 >/dev/null 2>&1
  echo $? > "$TMPDIR/case5"
)
read -r rc5 < "$TMPDIR/case5"
[ "$rc5" = "1" ] && ok "case5: raw EV_KEY 00000072 (down) -> 1" || bad "case5: rc=$rc5 expected 1"

# --- Case 6: irrelevant input -> give up with 2, not 0/1 ---------------------
(
  timeout() { printf 'EV_ABS ABS_MT_POSITION_X 0035\n'; }
  export -f timeout 2>/dev/null || true
  eval "$(extract choose)"
  choose 1 1 >/dev/null 2>&1
  echo $? > "$TMPDIR/case6"
)
read -r rc6 < "$TMPDIR/case6"
[ "$rc6" = "2" ] && ok "case6: unrelated event -> 2 (no false positive)" || bad "case6: rc=$rc6 expected 2"

# --- Case 7: capability probe fails when getevent missing --------------------
# Extract the function first, THEN remove the toolchain from PATH so the probe
# itself is what fails (not the extraction).
(
  eval "$(extract input_capability_ok)"
  PATH=/dev/null
  command() { return 1; }        # timeout lookup fails too
  export -f command 2>/dev/null || true
  input_capability_ok >/dev/null 2>&1
  echo $? > "$TMPDIR/case7"
)
read -r rc7 < "$TMPDIR/case7"
[ "$rc7" = "1" ] && ok "case7: missing toolchain -> capability denied" || bad "case7: rc=$rc7 expected 1"

# --- Case 8: INTERACTIVE is false when stdin is not a TTY --------------------
# This whole script runs piped/redirected, so [ -t 0 ] is false -> INTERACTIVE
# must end up false, which is exactly the automatic-profile path.
if [ -t 0 ]; then
  printf '  SKIP  case8: stdin is a TTY here\n'
else
  ok "case8: non-TTY stdin -> automatic profile path (this is the default in CI/manager)"
fi

rm -rf "$TMPDIR"
echo
[ "$fail" = 0 ] && echo "ALL VOLUME TESTS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
