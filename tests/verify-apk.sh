#!/usr/bin/env bash
# Verify an APK: package identity, versions, SDK range, permissions,
# signing certificates and SHA-256. Usage: verify-apk.sh <file.apk> [label]
set -u

APK="${1:?usage: verify-apk.sh <file.apk> [label]}"
LABEL="${2:-$APK}"

BT=/home/ansh/android-sdk/build-tools/36.0.0
export JAVA_HOME=/home/ansh/jdk17
export PATH="$JAVA_HOME/bin:$PATH"

[ -f "$APK" ] || { echo "NOT FOUND: $APK"; exit 2; }

echo "=== $LABEL ==="
echo "file        : $(basename "$APK")"
echo "size        : $(stat -c%s "$APK") bytes"
echo "sha256      : $(sha256sum "$APK" | cut -d' ' -f1)"

BADGING=$("$BT/aapt" dump badging "$APK" 2>/dev/null)
if [ -z "$BADGING" ]; then
  echo "badging     : UNREADABLE (not a valid APK?)"
  exit 3
fi

pkg=$(printf '%s' "$BADGING" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -1)
ver=$(printf '%s' "$BADGING" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" | head -1)
vnm=$(printf '%s' "$BADGING" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p" | head -1)
minsdk=$(printf '%s' "$BADGING" | sed -n "s/.*sdkVersion:'\([^']*\)'.*/\1/p" | head -1)
tgsdk=$(printf '%s' "$BADGING" | sed -n "s/.*targetSdkVersion:'\([^']*\)'.*/\1/p" | head -1)
label=$(printf '%s' "$BADGING" | sed -n "s/^application-label:'\(.*\)'$/\1/p" | head -1)

echo "package id  : $pkg"
echo "versionName : $vnm   (versionCode $ver)"
echo "minSdk      : $minsdk   targetSdk: $tgsdk"
echo "label       : $label"

# Native code / ABI
abis=$(printf '%s' "$BADGING" | sed -n "s/^native-code: //p" | head -1)
[ -n "$abis" ] && echo "native-code : $abis"

# Signing certificates (SHA-256 of each signer cert)
echo "signers     :"
"$BT/apksigner" verify --print-certs "$APK" 2>/dev/null \
  | sed -n 's/^\(Signer #1 certificate DN\|Signer #1 certificate SHA-256 digest\|Signer #1 certificate SHA-1 digest\)[[:space:]]*:[[:space:]]*/    /p' \
  || echo "    (apksigner failed)"

# Count and list privileged-relevant permissions
nperm=$(printf '%s' "$BADGING" | grep -c "^uses-permission:")
echo "permissions  : $nperm"
printf '%s' "$BADGING" | sed -n "s/^uses-permission: name='\([^']*\)'.*/    \1/p" | head -25
echo "---"
