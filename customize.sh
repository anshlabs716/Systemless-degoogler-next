#!/system/bin/sh

# Select the aapt binary for this device, with an alternate-ABI fallback.
chmod 755 "$MODPATH"/tools/aapt "$MODPATH"/tools/aapt64
case "$(getprop ro.product.cpu.abi)" in
  *64*) AAPT=aapt64 ;;
  *) AAPT=aapt ;;
esac
if ! "$MODPATH/tools/$AAPT" version >/dev/null 2>&1; then
  case "$AAPT" in aapt) AAPT=aapt64 ;; *) AAPT=aapt ;; esac
fi
if "$MODPATH/tools/$AAPT" version >/dev/null 2>&1; then
  cp -f "$MODPATH/tools/$AAPT" "$MODPATH/aapt"
else
  AAPT=
fi

choose() {
  # Original idea by chainfire and ianmacd @xda-developers
  [ "$1" ] && local delay=$1 || local delay=3
  local error=false
  while true; do
    local count=0
    while true; do
      timeout "$delay" /system/bin/getevent -lqc 1 >"$TMPDIR/events" 2>&1
      count=$((count + 1))
      if grep -q 'KEY_VOLUMEUP *DOWN' "$TMPDIR/events"; then
        return 0
      elif grep -q 'KEY_VOLUMEDOWN *DOWN' "$TMPDIR/events"; then
        return 1
      fi
      [ $count -gt 6 ] && break
    done
    if [ "$error" = true ]; then
      echo "Volume key not detected. Try again"
    fi
    error=true
  done
}

# DerpFest GApps contents vary by device/build. Add installed Google app
# packages dynamically so bundles missing from the static list are covered.
debloat_list="$TMPDIR/degoogler-packages.txt"
cat "$MODPATH/bloat_packagelist.txt" > "$debloat_list"
pm list packages 2>/dev/null | sed -n 's/^package:\(com\.google\.android\.apps\..*\)$/\1/p' >> "$debloat_list"
awk '!seen[$0]++' "$debloat_list" > "$debloat_list.tmp" && mv "$debloat_list.tmp" "$debloat_list"
id=$(grep "id=" $MODPATH/module.prop | cut -d'=' -f2-)
last_install="/data/adb/modules/$id"

if [ -f "$last_install/.lastreplace" ]; then
  REPLACE=""
  ui_print "- Installing... (𝗧𝗵𝗶𝘀 𝗰𝗼𝘂𝗹𝗱 𝘁𝗮𝗸𝗲 𝘀𝗼𝗺𝗲 𝘁𝗶𝗺𝗲 :𝗗)"
else
  REPLACE=$(cat "$last_install/.lastreplace")
  REPLACE="$REPLACE "
  ui_print "- (𝗥𝗲) Installing... (𝗧𝗵𝗶𝘀 𝗰𝗼𝘂𝗹𝗱 𝘁𝗮𝗸𝗲 𝘀𝗼𝗺𝗲 𝘁𝗶𝗺𝗲 :𝗗)"
fi

ui_print
ui_print "| Do you want to install with"
ui_print "|  The default configuration?"
ui_print "|               [● 𝗣𝗿𝗲𝘀𝘀 𝗩𝗼𝗹+]"
ui_print "|"
ui_print "| Or Customize your Installation?"
ui_print "|               [● 𝗣𝗿𝗲𝘀𝘀 𝗩𝗼𝗹-]"
ui_print "|"
ui_print "| Waiting until a key is pressed..."
ui_print

if choose 15; then
  ui_print "- Installing With the default config..."
  CUSTOMIZE=false
else
  ui_print "- OK, Lets customize the installation :D"
  ui_print
  CUSTOMIZE=true
fi

# Loop through each line in the output of the one-liner
while IFS= read -r PACKAGE_NAME; do
  # Check if the line is empty
  case "$PACKAGE_NAME" in
    ''|'#'*) continue ;;
  esac
  # Explicit keep list requested for DerpFest on Raven.
  case "$PACKAGE_NAME" in
    com.google.android.apps.nexuslauncher|com.google.android.packageinstaller|com.google.android.ext.services|com.google.android.ext.shared|com.google.android.GoogleCamera|com.google.android.documentsui|com.google.android.ims|com.google.android.webview|com.google.android.settings.intelligence|com.google.android.apps.wallpaper|com.google.android.apps.wallpaper.*|com.google.android.apps.setupwizard)
      continue ;;
  esac
  # Retain other Pixel-only features. Camera packages remain candidates for
  # removal except the exact Google Camera package protected above.
  case "$PACKAGE_NAME" in
    com.google.android.apps.pixel*|com.google.android.apps.wellbeing|com.google.android.apps.emojiwallpaper|com.google.android.apps.customization.pixel|com.google.android.apps.recorder|com.google.android.apps.safetyhub|com.google.android.apps.tips|com.google.android.apps.photos|com.google.android.apps.turbo|com.google.android.apps.markup|com.google.android.as|com.google.android.as.oss)
      continue ;;
  esac

  #        Get The Path of the App | Remove "package:"
  APP_PATH=$(pm path "$PACKAGE_NAME" 2>/dev/null | sed -n '1s/^package://p')

  if [ -z "$APP_PATH" ]; then
    continue
  fi

  APP_NAME=
  if [ -n "$AAPT" ]; then
    APP_NAME=$("$MODPATH"/aapt dump badging "$APP_PATH" 2>/dev/null | grep -Eo "application-label:'[^']+'" | sed -e "s/application-label://" -e "s/'//g")
  fi
  [ -n "$APP_NAME" ] || APP_NAME=$PACKAGE_NAME
  APP_PATH_FOLDER=${APP_PATH%/*}

  if [ $CUSTOMIZE == true ]; then
    ui_print
    ui_print "UnInstall $APP_NAME ($PACKAGE_NAME)?"
    ui_print "[● 𝗬𝗲𝘀: 𝗩𝗼𝗹+] [● 𝗡𝗼: 𝗩𝗼𝗹-]"

    if ! choose 15; then
      ui_print "- Didn't UnInstall $APP_NAME ($PACKAGE_NAME)"
      continue
    fi

  fi

  # Remove app-private data (accounts cached by Google apps, preferences,
  # databases, and caches) after the user accepts removing the app.
  pm clear "$PACKAGE_NAME" >/dev/null 2>&1

  case "$APP_PATH_FOLDER" in
    /data/app/*)
      pm uninstall --user 0 "$PACKAGE_NAME" >/dev/null 2>&1
      rm -rf "$APP_PATH_FOLDER"
      ui_print "- Removed app and local data for $APP_NAME"
      continue
      ;;
  esac

  # Magisk replaces paths under its system mount. Prefix product/vendor paths
  # with /system so the relative partition path remains correct.
  case "$APP_PATH_FOLDER" in
    /system/*) ;;
    /apex/*) ui_print "- Skipped APEX package $PACKAGE_NAME"; continue ;;
    /*) APP_PATH_FOLDER="/system$APP_PATH_FOLDER" ;;
  esac

  REPLACE="$REPLACE$APP_PATH_FOLDER "
  ui_print "- UnInstalled $APP_NAME ($PACKAGE_NAME)"

done < "$debloat_list"

echo $REPLACE > "$MODPATH/.lastreplace"

ui_print "- ******************** 𝗡𝗢𝗧𝗜𝗖𝗘 ********************"
ui_print "-        𝗜𝗳 𝗮𝗻𝘆 𝗮𝗽𝗽𝘀 𝗮𝗿𝗲 𝗹𝗲𝗳𝘁, 𝗜𝗻𝘀𝘁𝗮𝗹𝗹 𝘁𝗵𝗲 𝗺𝗼𝗱𝘂𝗹𝗲     "
ui_print "-           𝗔𝗴𝗮𝗶𝗻 𝗪𝗜𝗧𝗛𝗢𝗨𝗧 𝗿𝗲𝗺𝗼𝘃𝗶𝗻𝗴 𝗶𝘁 𝗳𝗶𝗿𝘀𝘁         "
ui_print "- ************************************************"

ui_print "- ************************************"
ui_print "- Installation Done! Reboot & Enjoy :)"
ui_print "- ************************************"
