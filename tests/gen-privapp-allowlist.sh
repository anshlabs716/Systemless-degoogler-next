#!/usr/bin/env bash
# Derive a minimal priv-app permission allowlist.
#
# For an app built INTO the ROM, Android auto-generates the priv-app allowlist.
# An app dropped into system/priv-app by a root module gets no such allowlist,
# so any privileged permission it requests is silently denied at runtime.
# This script reads AOSP's own framework manifest to learn which of the
# requested permissions are actually `privileged`, and emits an allowlist
# containing ONLY those - never a blanket grant.
#
# Usage: gen-privapp-allowlist.sh <framework AndroidManifest.xml> [output.xml]
set -euo pipefail

FWMAN="${1:?usage: gen-privapp-allowlist.sh <framework-manifest.xml> [out.xml]}"
OUT="${2:-}"

BT=/home/ansh/android-sdk/build-tools/36.0.0
export JAVA_HOME=/home/ansh/jdk17
export PATH="$JAVA_HOME/bin:$PATH"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIVAPP_DIR="$ROOT/system/priv-app"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 1. permission name -> protectionLevel, from the framework manifest.
python3 - "$FWMAN" "$tmp/perm.tsv" <<'PY'
import re, sys, html
src = open(sys.argv[1], encoding='utf-8', errors='replace').read()
out = open(sys.argv[2], 'w')
# only <permission .../> declarations (not permission-group / permission-tree)
for m in re.finditer(r'<permission\b[^>]*?/>', src, re.S):
    tag = m.group(0)
    if re.search(r'<permission-(group|tree)\b', tag):
        continue
    n = re.search(r'android:name="([^"]+)"', tag)
    p = re.search(r'android:protectionLevel="([^"]+)"', tag)
    if not n:
        continue
    level = p.group(1) if p else 'normal'
    level = html.unescape(level)
    out.write(f"{n.group(1)}\t{level}\n")
out.close()
PY

# 2. permissions requested by each bundled priv-app.
: > "$tmp/req.tsv"
for apk in "$PRIVAPP_DIR"/*/*.apk; do
  [ -f "$apk" ] || continue
  app=$(basename "$(dirname "$apk")")
  "$BT/aapt" dump permissions "$apk" 2>/dev/null \
    | sed -n "s/^ *uses-permission: name='\([^']*\)'.*/\1/p" \
    | while IFS= read -r perm; do printf '%s\t%s\n' "$app" "$perm"; done >> "$tmp/req.tsv"
done

# 3. intersect: requested AND privileged in AOSP.
python3 - "$tmp/perm.tsv" "$tmp/req.tsv" "$tmp/allow.tsv" <<'PY'
import sys
levels = {}
for line in open(sys.argv[1]):
    line = line.rstrip('\n')
    if not line: continue
    n, _, lvl = line.partition('\t')
    levels[n] = lvl

wanted = {}   # app -> ordered list of privileged perms
for line in open(sys.argv[2]):
    line = line.rstrip('\n')
    if not line: continue
    app, _, perm = line.partition('\t')
    lvl = levels.get(perm)
    if lvl is None:
        continue            # not declared in framework (custom/vendor) -> not allowlistable
    flags = lvl.split('|')
    if 'privileged' in flags:
        wanted.setdefault(app, []).append((perm, lvl))

with open(sys.argv[3], 'w') as f:
    for app in sorted(wanted):
        for perm, lvl in sorted(set(wanted[app])):
            f.write(f"{app}\t{perm}\t{lvl}\n")
PY

echo "=== privileged permissions found (requested + privileged in AOSP) ==="
if [ -s "$tmp/allow.tsv" ]; then
  column -t -s$'\t' "$tmp/allow.tsv"
else
  echo "(none - no allowlist needed)"
fi

if [ -n "$OUT" ]; then
  python3 - "$tmp/allow.tsv" "$OUT" <<'PY'
import sys, collections
rows = collections.defaultdict(list)
for line in open(sys.argv[1]):
    line = line.rstrip('\n')
    if not line: continue
    app, perm, _ = line.split('\t')
    rows[app].append(perm)

# Allowlist keys are package names; entries are permission names.
pkg_to_dir = {
    'WebViewGoogle': 'com.android.webview',
    'Dialer': 'com.android.dialer',
    'Contacts': 'com.android.contacts',
    'Messaging': 'com.android.messaging',
    'DeskClock': 'com.android.deskclock',
    'DocumentsUI': 'com.android.documentsui',
    'LineageOSCalendar': 'org.lineageos.etar',
    'Recorder': 'org.lineageos.recorder',
}
lines = ['<?xml version="1.0" encoding="utf-8"?>',
         '<!-- Auto-derived by tests/gen-privapp-allowlist.sh from AOSP framework',
         '     protectionLevel data. Contains ONLY permissions that are both',
         '     requested by the bundled priv-app and declared `privileged` in',
         '     AOSP - no blanket grants. -->',
         '<permissions>']
for app in sorted(rows):
    pkg = pkg_to_dir.get(app, app)
    lines.append(f'    <privapp-permissions package="{pkg}">')
    for p in sorted(set(rows[app])):
        lines.append(f'        <permission name="{p}"/>')
    lines.append('    </privapp-permissions>')
lines.append('</permissions>')
open(sys.argv[2], 'w').write('\n'.join(lines) + '\n')
PY
  echo
  echo "wrote $OUT"
fi
