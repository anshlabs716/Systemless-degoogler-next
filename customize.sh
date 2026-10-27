#!/system/bin/sh

# Select the aapt binary for this device, with an alternate-ABI fallback.
chmod 755 "$MODPATH"/tools/aapt "$MODPATH"/tools/aapt64
chmod 755 "$MODPATH"/service.sh 2>/dev/null
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
force_list="$MODPATH/force_packagelist.txt"
id=$(sed -n 's/^id=//p' "$MODPATH/module.prop" | head -n 1)
last_install="/data/adb/modules/$id"
REMOVE=""
SEEN=""

# Never leave the device without an input method. Gboard is often the only
# *enabled* keyboard, so a non-Google keyboard is enabled and made the default
# before it is removed. Returns 1 when no replacement keyboard exists, which
# tells the caller to keep Gboard.
ensure_keyboard() {
  CURRENT=$(settings get secure default_input_method 2>/dev/null)
  case "$CURRENT" in
    com.google.android.inputmethod.latin/*|null|'')
      : ;;
    *)
      # Default is already a non-Google keyboard.
      return 0 ;;
  esac

  # Prefer a keyboard that is already enabled.
  for IME in $(ime list -s 2>/dev/null); do
    case "$IME" in com.google.android.inputmethod.latin/*) continue ;; esac
    if ime set "$IME" >/dev/null 2>&1; then
      ui_print "- Default keyboard switched to ${IME%%/*}."
      return 0
    fi
  done

  # Otherwise enable an installed alternative, then make it the default.
  for IME in $(ime list -a 2>/dev/null | sed -n 's/^\([^:[:space:]]*\)\/\([^:[:space:]]*\):.*/\1\/\2/p'); do
    case "$IME" in com.google.android.inputmethod.latin/*) continue ;; esac
    ime enable "$IME" >/dev/null 2>&1
    if ime set "$IME" >/dev/null 2>&1; then
      ui_print "- Enabled and set keyboard ${IME%%/*}."
      return 0
    fi
  done

  ui_print "- No alternative keyboard found."
  return 1
}

# Mask or disable a single package.
#   $1 = package name
#   $2 = "true" when the package is force-removed (never prompted)
process_package() {
  PACKAGE_NAME=$1
  FORCED=$2

  # Allow trailing "#" comments and stray whitespace in the package lists.
  case "$PACKAGE_NAME" in ''|'#'*) return 0 ;; esac
  PACKAGE_NAME=${PACKAGE_NAME%%#*}
  PACKAGE_NAME=$(printf '%s' "$PACKAGE_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  case "$PACKAGE_NAME" in '') return 0 ;; esac

  # Already handled this pass; keeps packages that appear in both lists from
  # being recorded twice.
  case " $SEEN " in *" $PACKAGE_NAME "*) return 0 ;; esac
  SEEN="$SEEN $PACKAGE_NAME "

  # Defense-in-depth: protect essential Google compatibility services and
  # explicitly excluded camera/core components even if added to the text list.
  case "$PACKAGE_NAME" in
    com.google.android.gms|com.google.android.gsf|com.google.android.onetimeinitializer|com.google.android.packageinstaller|com.google.android.ext.services|com.google.android.ext.shared|com.google.android.GoogleCamera|com.google.android.apps.wallpaper|com.google.android.apps.wallpaper.*|com.google.android.documentsui|com.google.android.ims|com.google.android.webview|com.google.android.settings.intelligence|com.google.android.apps.nexuslauncher|com.google.android.apps.pixel*|com.google.android.apps.customization.pixel|com.google.android.markup|com.android.providers.settings|com.android.settings.auto_generated_rro_product__)
      return 0 ;;
  esac

  APP_PATH=$(pm path "$PACKAGE_NAME" 2>/dev/null | sed -n '1s/^package://p')
  [ -n "$APP_PATH" ] || return 0
  APP_PATH_FOLDER=${APP_PATH%/*}

  # APEX modules and core Android settings/overlay infrastructure are outside
  # this app-masker's scope. Never delete user app data or updated APKs.
  case "$APP_PATH_FOLDER" in
    /apex/*)
      ui_print "- Skipped APEX package $PACKAGE_NAME."
      return 0 ;;
    /data/app/*)
      # An update moved this APK out of the system image, so a systemless mask
      # can never reach it. Force-removed packages fall back to disabling the
      # app for user 0; optional ones stay untouched.
      if [ "$FORCED" = true ]; then
        if pm uninstall --user 0 "$PACKAGE_NAME" >/dev/null 2>&1; then
          ui_print "- Disabled updated build of $PACKAGE_NAME (user 0)."
        else
          ui_print "- Failed to disable $PACKAGE_NAME."
        fi
      else
        ui_print "- Skipped updated/user-installed app $PACKAGE_NAME; no data was changed."
      fi
      return 0 ;;
  esac

  APP_NAME=$PACKAGE_NAME
  if [ -n "$AAPT" ]; then
    LABEL=$("$MODPATH/aapt" dump badging "$APP_PATH" 2>/dev/null | sed -n "s/^application-label:'\(.*\)'$/\1/p" | head -n 1)
    [ -n "$LABEL" ] && APP_NAME=$LABEL
  fi

  # Force-removed packages never reach a volume-key prompt, so a missed or
  # timed-out prompt can no longer silently keep them installed.
  if [ "$FORCED" != true ] && [ "$CUSTOMIZE" = true ]; then
    ui_print
    ui_print "Remove $APP_NAME?"
    ui_print "[● Volume Up: Yes] [● Volume Down: No]"
    if ! choose 15; then
      ui_print "- Kept $APP_NAME."
      return 0
    fi
  fi

  case "$APP_PATH_FOLDER" in
    /system/*) ;;
    /*) APP_PATH_FOLDER="/system$APP_PATH_FOLDER" ;;
    *) ui_print "- Skipped unknown path $APP_PATH_FOLDER"; return 0 ;;
  esac

  REMOVE="$REMOVE$APP_PATH_FOLDER "
  ui_print "- Systemlessly masked $APP_NAME."
}

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

# 0. Gboard. Promote a non-Google keyboard first so the device is never left
#    without a way to type, then remove it.
GB="com.google.android.inputmethod.latin"
if pm path "$GB" >/dev/null 2>&1; then
  ui_print
  if ensure_keyboard; then
    process_package "$GB" true
  else
    ui_print "- Kept Gboard: no alternative keyboard available to take over."
  fi
fi

# 1. Always-on removals (Gmail, Google Search, Maps, Photos, Pixel Weather,
#    Files by Google). These were silently kept by earlier installs.
if [ -f "$force_list" ]; then
  ui_print
  ui_print "| Removing the always-listed Google apps (no prompt)..."
  while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
    process_package "$PACKAGE_NAME" true
  done < "$force_list"
fi

# 2. Reviewed optional list, prompted only in per-app mode.
if [ -f "$debloat_list" ]; then
  while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
    process_package "$PACKAGE_NAME" false
  done < "$debloat_list"
fi

# 3. Duplicate Proton Pass: keep the regular build, disable the F-Droid build.
#    Both bundle the same app, so only one should remain installed.
DUP_PASS="proton.android.pass.fdroid"
ui_print
if pm path proton.android.pass >/dev/null 2>&1 && pm path "$DUP_PASS" >/dev/null 2>&1; then
  if pm uninstall --user 0 "$DUP_PASS" >/dev/null 2>&1; then
    ui_print "- Disabled duplicate Proton Pass (F-Droid build); regular build kept."
  else
    ui_print "- Could not disable duplicate Proton Pass (F-Droid build)."
  fi
else
  ui_print "- No duplicate Proton Pass build detected; nothing changed."
fi

printf '%s\n' "$REMOVE" > "$MODPATH/.lastremove"
ui_print "- Done. Reboot to apply the module."
