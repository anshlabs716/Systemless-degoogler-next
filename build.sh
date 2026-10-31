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

# system/ carries the privileged suite (system/priv-app) and MILES
# (system/app). It is required for the current layout.
[ -d system ] || { echo "system/ directory is missing; cannot build" >&2; exit 1; }
priv_count=$(find system/priv-app -name '*.apk' 2>/dev/null | wc -l)
if [ "$priv_count" -ne 8 ]; then
  echo "expected 8 APKs under system/priv-app, found $priv_count" >&2
  find system/priv-app -name '*.apk' 2>/dev/null >&2
  exit 1
fi
[ -f system/app/MILES/MILES.apk ] || { echo "system/app/MILES/MILES.apk is missing" >&2; exit 1; }

rm -f "$mod_id-$version.zip" "$mod_id-$version-ksu.zip"
if [ "$format" = ksu ]; then
  # KernelSU variant ships without the Magisk META-INF updater and carries a
  # distinct asset name so both can sit on the same release.
  output="$mod_id-$version-ksu.zip"
  zip -r "$output" module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools pkgs system \
    -x 'pkgs/*fossify*.apk' 'pkgs/*Fossify*.apk' \
    'pkgs/30_*.apk' 'pkgs/31_*.apk' 'pkgs/32_*.apk' 'pkgs/33_*.apk' \
    'pkgs/34_*.apk' 'pkgs/35_*.apk' 'pkgs/36_*.apk' 'pkgs/37_*.apk'
else
  output="$mod_id-$version.zip"
  zip -r "$output" META-INF module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools pkgs system \
    -x 'pkgs/*fossify*.apk' 'pkgs/*Fossify*.apk' \
    'pkgs/30_*.apk' 'pkgs/31_*.apk' 'pkgs/32_*.apk' 'pkgs/33_*.apk' \
    'pkgs/34_*.apk' 'pkgs/35_*.apk' 'pkgs/36_*.apk' 'pkgs/37_*.apk'
fi
echo "built $output"
