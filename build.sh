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
output="$mod_id-$version.zip"
rm -f "$output"
if [ "$format" = ksu ]; then
  zip -r "$output" module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools pkgs
else
  zip -r "$output" META-INF module.prop bloat_packagelist.txt force_packagelist.txt customize.sh service.sh tools pkgs
fi
