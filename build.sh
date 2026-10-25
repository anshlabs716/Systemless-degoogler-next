#!/usr/bin/env bash
set -euo pipefail

version="${1:-TEST}"
mod_id="$(sed -n 's/^id=//p' module.prop | head -n 1)"
[ -n "$mod_id" ] || { echo "module.prop has no id" >&2; exit 1; }
command -v wget >/dev/null || { echo "wget is required" >&2; exit 1; }
command -v zip >/dev/null || { echo "zip is required" >&2; exit 1; }

mkdir -p tools pkgs
for tool in aapt aapt64; do
  [ -s "tools/$tool" ] || wget -q -O "tools/$tool" "https://raw.githubusercontent.com/Systemless-DeBloaters/Framework/main/tools/$tool"
  chmod 755 "tools/$tool"
done
chmod 755 service.sh
zip -r "$mod_id-$version.zip" META-INF module.prop bloat_packagelist.txt customize.sh service.sh tools pkgs
