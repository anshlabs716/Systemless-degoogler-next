#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

version="${1:-TEST}"
format="${2:-magisk}"
case "$version" in
  ""|*[!A-Za-z0-9._-]*) echo "version may contain only letters, numbers, dots, underscores, and hyphens" >&2; exit 1 ;;
esac
mod_id="$(sed -n 's/^id=//p' module.prop | head -n 1)"
[ -n "$mod_id" ] || { echo "module.prop has no id" >&2; exit 1; }
case "$format" in
  magisk|ksu) ;;
  *) echo "format must be magisk or ksu" >&2; exit 1 ;;
esac
command -v wget >/dev/null || { echo "wget is required" >&2; exit 1; }
command -v zip >/dev/null || { echo "zip is required" >&2; exit 1; }

mkdir -p tools pkgs
for tool in aapt aapt64; do
  [ -s "tools/$tool" ] || wget -q -O "tools/$tool" "https://raw.githubusercontent.com/Systemless-DeBloaters/Framework/main/tools/$tool"
  chmod 755 "tools/$tool"
done
chmod 755 service.sh

# system/ carries all regular and privileged APKs in their system app slots.
[ -d system ] || { echo "system/ directory is missing; cannot build" >&2; exit 1; }
regular_count=$(find system/app -type f -name '*.apk' 2>/dev/null | wc -l)
if [ "$regular_count" -ne 24 ]; then
  echo "expected 24 APKs under system/app, found $regular_count" >&2
  find system/app -type f -name '*.apk' 2>/dev/null >&2
  exit 1
fi
priv_count=$(find system/priv-app -type f -name '*.apk' 2>/dev/null | wc -l)
if [ "$priv_count" -ne 7 ]; then
  echo "expected 7 APKs under system/priv-app, found $priv_count" >&2
  find system/priv-app -name '*.apk' 2>/dev/null >&2
  exit 1
fi
[ -z "$(find pkgs -type f -name '*.apk' -print -quit 2>/dev/null)" ] || {
  echo "APK files must be staged only under system/app or system/priv-app" >&2
  exit 1
}

rm -f "$mod_id-$version.zip" "$mod_id-$version-ksu.zip"
if [ "$format" = ksu ]; then
  # KernelSU variant ships without the Magisk META-INF updater and carries a
  # distinct asset name so both can sit on the same release.
  output="$mod_id-$version-ksu.zip"
  zip -r "$output" module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools system
else
  output="$mod_id-$version.zip"
  zip -r "$output" META-INF module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools system
fi
echo "built $output"
