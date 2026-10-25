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
  [ "$1" ] && delay=$1 || delay=3
  while true; do
    timeout "$delay" /system/bin/getevent -lqc 1 >"$TMPDIR/events" 2>&1
    if grep -q 'KEY_VOLUMEUP *DOWN' "$TMPDIR/events"; then
      return 0
    elif grep -q 'KEY_VOLUMEDOWN *DOWN' "$TMPDIR/events"; then
      return 1
    fi
    ui_print "- Volume key not detected. Try again."
  done
}

# Only process the reviewed static list. In particular, do not automatically
# sweep packages from the device's com.google.android.apps namespace.
debloat_list="$MODPATH/bloat_packagelist.txt"
id=$(sed -n 's/^id=//p' "$MODPATH/module.prop" | head -n 1)
last_install="/data/adb/modules/$id"
REPLACE=""

ui_print
ui_print "| Install the default optional-app list?"
ui_print "| [● Volume Up: Yes]"
ui_print "| [● Volume Down: Choose apps one by one]"
ui_print "| Waiting for a volume key..."
if choose 15; then
  CUSTOMIZE=false
else
  CUSTOMIZE=true
fi

while IFS= read -r PACKAGE_NAME; do
  case "$PACKAGE_NAME" in ''|'#'*) continue ;; esac

  # Defense-in-depth: protect core services, phone/setup components, and the
  # requested Raven Pixel features even if someone adds them to the text list.
  case "$PACKAGE_NAME" in
    com.google.android.gms|com.google.android.gsf|com.google.android.setupwizard|com.google.android.onetimeinitializer|com.google.android.packageinstaller|com.google.android.ext.services|com.google.android.ext.shared|com.google.android.GoogleCamera|com.google.android.documentsui|com.google.android.ims|com.google.android.webview|com.google.android.settings.intelligence|com.google.android.apps.nexuslauncher|com.google.android.apps.wallpaper|com.google.android.apps.wallpaper.*|com.google.android.dialer|com.google.android.contacts|com.google.android.syncadapters.contacts|com.google.android.apps.messaging|com.google.android.inputmethod.latin|com.google.android.as|com.google.android.as.oss|com.google.android.apps.pixel*|com.google.android.apps.wellbeing|com.google.android.apps.emojiwallpaper|com.google.android.apps.customization.pixel|com.google.android.apps.recorder|com.google.android.apps.safetyhub|com.google.android.apps.photos|com.google.android.apps.turbo|com.google.android.markup)
      continue ;;
  esac

  APP_PATH=$(pm path "$PACKAGE_NAME" 2>/dev/null | sed -n '1s/^package://p')
  [ -n "$APP_PATH" ] || continue
  APP_PATH_FOLDER=${APP_PATH%/*}

  # Never delete user app data or an updated APK. Mask only reviewed system apps.
  case "$APP_PATH_FOLDER" in
    /data/app/*)
      ui_print "- Skipped updated/user-installed app $PACKAGE_NAME; no data was changed."
      continue ;;
    /apex/*)
      ui_print "- Skipped APEX package $PACKAGE_NAME."
      continue ;;
  esac

  APP_NAME=$PACKAGE_NAME
  if [ -n "$AAPT" ]; then
    LABEL=$("$MODPATH/aapt" dump badging "$APP_PATH" 2>/dev/null | sed -n "s/^application-label:'\(.*\)'$/\1/p" | head -n 1)
    [ -n "$LABEL" ] && APP_NAME=$LABEL
  fi

  if [ "$CUSTOMIZE" = true ]; then
    ui_print
    ui_print "Remove $APP_NAME?"
    ui_print "[● Volume Up: Yes] [● Volume Down: No]"
    if ! choose 15; then
      ui_print "- Kept $APP_NAME."
      continue
    fi
  fi

  case "$APP_PATH_FOLDER" in
    /system/*) ;;
    /*) APP_PATH_FOLDER="/system$APP_PATH_FOLDER" ;;
    *) ui_print "- Skipped unknown path $APP_PATH_FOLDER"; continue ;;
  esac

  REPLACE="$REPLACE$APP_PATH_FOLDER "
  ui_print "- Systemlessly masked $APP_NAME."
done < "$debloat_list"

printf '%s\n' "$REPLACE" > "$MODPATH/.lastreplace"
ui_print "- Done. Reboot to apply the module."
