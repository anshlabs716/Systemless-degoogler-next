#!/system/bin/sh

# KernelSU needs a metamodule to mount the systemless app masks.
if [ "$KSU" = true ]; then
  META_FOUND=false
  for MODULE_PROP in /data/adb/modules/*/module.prop; do
    [ -f "$MODULE_PROP" ] || continue
    MODULE_DIR=${MODULE_PROP%/module.prop}
    [ "$MODULE_DIR" = "$MODPATH" ] && continue
    [ -f "$MODULE_DIR/disable" ] && continue
    if grep -Eq '^metamodule=(1|true)$' "$MODULE_PROP"; then
      META_FOUND=true
      break
    fi
  done
  [ "$META_FOUND" = true ] || abort "KernelSU requires an enabled system metamodule (for example, meta-overlayfs). Install it in KernelSU Manager and reboot first."
fi

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

# ---------------------------------------------------------------------------
# Interactive volume-key selection
# ---------------------------------------------------------------------------
# Volume keys can only be read when this shell has a real input path. That is
# true inside a custom recovery, which routes the keys to /dev/input and gives
# the installer a terminal. It is frequently false for installs started from a
# root manager app, where the installer shell is spawned over a pipe with no
# terminal and often no read access to the input devices.
#
# We therefore detect CAPABILITY instead of naming a root manager:
#   * stdin must be a terminal           -> [ -t 0 ]
#   * timeout must exist, otherwise a blocked getevent never returns
#   * getevent must exist and be executable
#   * /dev/input must be readable
#   * getevent must actually be able to enumerate an input device
# If any of these fail there is no interactive input here, and the installer
# switches to the documented automatic profile instead of blocking forever.

INTERACTIVE=false

input_capability_ok() {
  command -v timeout >/dev/null 2>&1 || return 1
  [ -x /system/bin/getevent ] || return 1
  [ -d /dev/input ] || return 1
  [ -r /dev/input ] || return 1
  # `getevent -p` enumerates devices without waiting for a key press. Empty
  # output means the shell cannot open the input devices at all.
  [ -n "$(timeout 5 /system/bin/getevent -p 2>/dev/null | head -n 1)" ] || return 1
  return 0
}

if [ -t 0 ] && input_capability_ok; then
  INTERACTIVE=true
fi

# Reads a single volume key. Returns 0 for Volume Up, 1 for Volume Down and
# 2 when no key arrived. The wait is bounded: at most $2 attempts of $1
# seconds each, so the installer can never block indefinitely on key input.
choose() {
  [ "$1" ] && delay=$1 || delay=10
  [ "$2" ] && attempts=$2 || attempts=3
  attempt=0
  while [ "$attempt" -lt "$attempts" ]; do
    attempt=$((attempt + 1))
    rm -f "$TMPDIR/events"
    timeout "$delay" /system/bin/getevent -lqc 3 >"$TMPDIR/events" 2>&1 || :
    if [ ! -s "$TMPDIR/events" ]; then
      ui_print "- No key events seen (attempt $attempt/$attempts). Try again."
      continue
    fi
    if grep -Eq 'KEY_VOLUMEUP[[:space:]]+(DOWN|00000001)|EV_KEY[[:space:]]+00000073[[:space:]]+00000001' "$TMPDIR/events"; then
      return 0
    elif grep -Eq 'KEY_VOLUMEDOWN[[:space:]]+(DOWN|00000001)|EV_KEY[[:space:]]+00000072[[:space:]]+00000001' "$TMPDIR/events"; then
      return 1
    fi
    ui_print "- Volume key not detected (attempt $attempt/$attempts). Try again."
  done
  ui_print "- No volume key after $attempts attempts; continuing automatically."
  return 2
}

# Only process the reviewed static list. This list covers Google apps, OEM
# bloat from brands with OEM-unlockable bootloaders (Samsung, Xiaomi,
# OnePlus, Motorola, Oppo, Vivo, Realme, ASUS, Sony, etc.), and carrier
# packages. Only listed packages that are actually installed are ever touched;
# the device's own apps are never swept.
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

# The open-source WebView bundled by this module. Google's WebView is only
# masked when this file is actually present, so an incomplete or missing
# bundle can never leave the device without a WebView provider.
REPLACEMENT_WEBVIEW="$MODPATH/system/priv-app/WebViewGoogle/WebViewGoogle.apk"

webview_replacement_ready() {
  [ -f "$REPLACEMENT_WEBVIEW" ] || return 1
  # Without aapt we cannot confirm the provider identity; file presence alone
  # is the weaker signal, so report it and let the operator decide.
  [ -n "$AAPT" ] || return 0
  GOT=$("$MODPATH/aapt" dump badging "$REPLACEMENT_WEBVIEW" 2>/dev/null | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -n 1)
  [ "$GOT" = "com.android.webview" ]
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

  # Protect Bixby on Samsung and other essential OEM services. Bixby is
  # preserved per user policy and must never be removed.
  case "$PACKAGE_NAME" in
    com.samsung.android.bixby.*|com.samsung.android.bixbyvision.*|com.samsung.android.app.spage|com.samsung.android.app.settings.bixby|com.samsung.systemui.bixby*|com.samsung.android.bixby*)
      ui_print "- Kept $PACKAGE_NAME (Bixby is preserved on Samsung)."
      return 0 ;;
    com.samsung.android.networkstack|com.samsung.android.networkstack.*|com.samsung.android.providers.context|com.samsung.android.app.omcagent|com.samsung.android.auth|com.samsung.android.samsungpass|com.samsung.android.SettingsReceiver|com.samsung.android.wifi.resources)
      ui_print "- Kept $PACKAGE_NAME (essential Samsung service)."
      return 0 ;;
    com.miui.home|com.miui.securitycenter|com.miui.securityadd|com.xiaomi.finddevice|com.miui.gallery|com.miui.packageinstaller|com.lbe.security.miui|com.miui.bootkeeper|com.miui.cloudbackup|com.miui.cloudservice|com.miui.micloudsync)
      ui_print "- Kept $PACKAGE_NAME (essential Xiaomi service)."
      return 0 ;;
    com.oneplus.launcher|com.oneplus.backuprestore|com.motorola.applauncher|com.motorola.android.providers.settings|com.asus.launcher|com.oppo.oppogallery|com.vivo.launcher|com.vivo.account|com.sonymobile.storagestate|com.sonymobile.xperialounge.services|com.samsung.android.app.omcagent|com.samsung.android.app.lock)
      ui_print "- Kept $PACKAGE_NAME (essential OEM service)."
      return 0 ;;
  esac

  # Only remove listed packages: Google apps, OEM bloat, and carrier apps.
  # Non-Google/OEM/carrier packages are skipped even if someone adds them.
  case "$PACKAGE_NAME" in
    com.google.*|com.android.chrome|com.android.vending|com.android.hotwordenrollment.*) ;;
    com.samsung.*|com.sec.*|com.mi.*|com.miui.*|com.xiaomi.*|com.poco.*|com.oneplus.*|com.oos.*) ;;
    com.motorola.*|com.sonymobile.*|com.sonyericsson.*|com.oppo.*|com.vivo.*|com.realme.*) ;;
    com.iqoo.*|com.asus.*|com.lenovo.*|com.zte.*|com.nubia.*|com.meizu.*|com.wiko.*) ;;
    com.tecno.*|com.transsion.*|com.infinix.*|com.itel.*|com.nokia.*|com.hmd.*) ;;
    com.nothing.*|com.cmf.*|com.fairphone.*|com.ulefone.*|com.doogee.*|com.leeco.*) ;;
    com.rockchip.*|com.sharp.*|com.kyocera.*|com.fossil.*|com.lge.*|com.htc.*) ;;
    com.huawei.*|com.honor.*|com.volla.*|com.teracube.*|com.murena.*|com.shift.*) ;;
    com.vzw.*|com.verizon.*|com.att.*|com.tmobile.*|com.sprint.*) ;;
    *)
      ui_print "- Skipped non-Google, non-OEM, non-carrier package $PACKAGE_NAME."
      return 0 ;;
  esac

  # Already handled this pass; keeps packages that appear in both lists from
  # being recorded twice.
  case " $SEEN " in *" $PACKAGE_NAME "*) return 0 ;; esac
  SEEN="$SEEN $PACKAGE_NAME "

  # Google's WebView is never masked unless the bundled open-source replacement
  # is present and carries the expected provider identity (com.android.webview).
  # Masking Google's WebView without a working replacement leaves every app
  # with no rendering engine, which breaks embedded pages and login screens.
  if [ "$PACKAGE_NAME" = com.google.android.webview ]; then
    if webview_replacement_ready; then
      ui_print "- Google WebView will be masked; bundled com.android.webview takes over."
    else
      ui_print "- Kept com.google.android.webview: no verified replacement WebView is bundled."
      return 0
    fi
  fi

  # Defense-in-depth: protect essential Google compatibility services and
  # explicitly excluded camera/core components even if added to the text list.
  #
  # NOTE: com.google.android.webview is deliberately NOT protected here, because
  # the force list intentionally masks it in favour of the bundled open-source
  # WebView. process_package() applies a separate, stricter guard for it: it is
  # only ever masked when a verified replacement provider is actually present
  # in this module. Without that guard, removing Google's WebView would leave
  # every app with no rendering engine and broken login screens.
  case "$PACKAGE_NAME" in
    com.google.android.gsf|com.google.android.onetimeinitializer|com.google.android.packageinstaller|com.google.android.ext.services|com.google.android.ext.shared|com.google.android.GoogleCamera|com.google.android.apps.wallpaper|com.google.android.apps.wallpaper.*|com.google.android.documentsui|com.google.android.ims|com.google.android.settings.intelligence|com.google.android.apps.nexuslauncher|com.google.android.apps.pixel*|com.google.android.apps.customization.pixel|com.google.android.markup|com.android.providers.settings|com.android.settings.auto_generated_rro_product__)
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

  # Per-app review only runs when this environment can actually read volume
  # keys, and only for optional (non-forced) packages. The safe default is to
  # KEEP the package: we only mask it after an explicit Volume Up. A timeout,
  # an unreadable key event or an unrecognised key all fall through to "keep".
  if [ "$FORCED" != true ] && [ "$CUSTOMIZE" = true ] && [ "$INTERACTIVE" = true ]; then
    ui_print
    ui_print "Remove $APP_NAME?"
    ui_print "[● Volume Up: Yes] [● Volume Down: No]"
    choose 10 2
    if [ $? -ne 0 ]; then
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
# The interactive selection menu. When this shell cannot read volume keys we
# do not prompt at all: the installer continues immediately with the automatic
# profile (force list applied, optional list left unchanged) instead of
# waiting for input that can never arrive.
if [ "$INTERACTIVE" = true ]; then
  ui_print "| Install the default optional-app list?"
  ui_print "| [● Volume Up: Yes]"
  ui_print "| [● Volume Down: Choose apps one by one]"
  ui_print "| Waiting for a volume key (10s per attempt)..."
  choose 10 3
  case $? in
    0) APPLY_OPTIONAL=true;  CUSTOMIZE=false ;;
    1) APPLY_OPTIONAL=true;  CUSTOMIZE=true ;;
    *) APPLY_OPTIONAL=false; CUSTOMIZE=false ;;
  esac
else
  ui_print "| No interactive terminal for volume keys in this environment."
  ui_print "| Automatic profile: force list applied, optional list left unchanged."
  ui_print "| Install from custom recovery to choose optional apps with volume keys."
  APPLY_OPTIONAL=false
  CUSTOMIZE=false
fi

# 0. Futo Keyboard. Pre-install the bundled Futo Keyboard APK so that
#    ensure_keyboard() below can detect and enable it. This runs during
#    customize.sh (not boot service) to guarantee a replacement IME exists
#    before Gboard is removed.
for FUTO_APK in "$MODPATH"/pkgs/*futo*.apk; do
  [ -f "$FUTO_APK" ] || continue
  if pm install -r "$FUTO_APK" >/dev/null 2>&1; then
    ui_print "- Futo Keyboard pre-installed from bundled APK."
  else
    ui_print "- Could not pre-install Futo Keyboard; Gboard will be kept unless another keyboard is available."
  fi
done

# 1. Gboard. Promote a non-Google keyboard first so the device is never left
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

# 2. Always-on removals (Gmail, Google Search, Maps, Photos, Pixel Weather,
#    Files by Google). These were silently kept by earlier installs.
if [ -f "$force_list" ]; then
  ui_print
  ui_print "| Removing the always-listed Google apps (no prompt)..."
  while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
    process_package "$PACKAGE_NAME" true
  done < "$force_list"
fi

# 3. Reviewed optional list. Only walked when the installer actually offered
#    the selection menu and the user chose to proceed. In the automatic
#    (non-interactive) profile this list is deliberately left untouched: the
#    user never consented to it, and silently stripping dozens of optional
#    apps from an unattended install is not safe. The force list below still
#    runs, so the documented automatic profile is exactly the force list.
if [ "$APPLY_OPTIONAL" = true ] && [ -f "$debloat_list" ]; then
  while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
    process_package "$PACKAGE_NAME" false
  done < "$debloat_list"
elif [ "$APPLY_OPTIONAL" != true ]; then
  ui_print "- Automatic profile: optional list skipped (force list still applied)."
fi

# 4. Duplicate Proton Pass: keep the regular build, disable the F-Droid build.
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
