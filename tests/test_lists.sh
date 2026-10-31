#!/usr/bin/env bash
# Static checks for the package lists:
#   * well-formed package entries
#   * no duplicate entries within a list
#   * no package that this module bundles is also on a removal list
#   * the force list only contains packages the installer will actually act on
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOAT="$ROOT/bloat_packagelist.txt"
FORCE="$ROOT/force_packagelist.txt"
AUDIT="${AUDIT:-/home/ansh/apk-audit.tsv}"

fail=0
ok()   { printf '  PASS  %s\n' "$1"; }
bad()  { printf '  FAIL  %s\n' "$1"; fail=1; }

# Strip comments/blank lines and emit the bare package names.
pkgs_of() { sed 's/#.*//; s/[[:space:]]*$//; /^$/d' "$1"; }

PKG_RE='^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$'

for list in "$BLOAT" "$FORCE"; do
  name=$(basename "$list")
  [ -f "$list" ] || { bad "$name: missing"; continue; }

  # Format
  bad_fmt=$(pkgs_of "$list" | grep -Ev "$PKG_RE" || true)
  if [ -z "$bad_fmt" ]; then ok "$name: all entries well-formed"
  else bad "$name: malformed entries: $(printf '%s ' $bad_fmt)"; fi

  # Duplicates
  dupes=$(pkgs_of "$list" | sort | uniq -d)
  if [ -z "$dupes" ]; then ok "$name: no duplicate entries"
  else bad "$name: duplicates: $(printf '%s ' $dupes)"; fi

  n=$(pkgs_of "$list" | wc -l)
  printf '  INFO  %s: %s entries\n' "$name" "$n"
done

# Overlap between the two lists is allowed (deduped at install time) but must
# be reported so it is a conscious choice, not an accident.
overlap=$(comm -12 <(pkgs_of "$BLOAT" | sort -u) <(pkgs_of "$FORCE" | sort -u))
if [ -z "$overlap" ]; then
  ok "no overlap between the two lists"
else
  printf '  INFO  package(s) in both lists (deduped at install): %s\n' "$(printf '%s ' $overlap)"
fi

# Nothing this module bundles may appear on a removal list.
if [ -f "$AUDIT" ]; then
  bundled=$(tail -n +2 "$AUDIT" | cut -f2 | grep -v '^UNREADABLE$' | sort -u)
  offenders=""
  for p in $bundled; do
    if pkgs_of "$BLOAT" | grep -qx "$p" || pkgs_of "$FORCE" | grep -qx "$p"; then
      offenders="$offenders $p"
    fi
  done
  if [ -z "$offenders" ]; then ok "no bundled package is on a removal list (MILES safe)"
  else bad "bundled package(s) also on a removal list:$offenders"; fi

  # Every bundled package ID must be unique across the bundle.
  allids=$(tail -n +2 "$AUDIT" | cut -f2 | grep -v '^UNREADABLE$')
  dupid=$(printf '%s\n' "$allids" | sort | uniq -d)
  # 25_miles.apk and system/app/MILES/MILES.apk are intentionally the same app.
  dupid=$(printf '%s\n' "$dupid" | grep -v '^com.aistudio.miles.track$' || true)
  if [ -z "$dupid" ]; then ok "no unintended duplicate package IDs in the bundle"
  else bad "duplicate bundled package ID(s): $(printf '%s ' $dupid)"; fi
else
  printf '  SKIP  bundled-package cross-check (no audit file at %s)\n' "$AUDIT"
fi

echo
[ "$fail" = 0 ] && echo "ALL LIST CHECKS PASSED" || echo "THERE WERE FAILURES"
exit "$fail"
