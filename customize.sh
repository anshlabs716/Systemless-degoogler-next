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
# Unattended install: no prompts, no volume keys
# ---------------------------------------------------------------------------
#
# There is deliberately NO volume-key prompt and no getevent call anywhere in
# this installer. Earlier versions asked one question ("apply the default
# optional list?") and used the volume keys to answer it, but that never
# changed WHAT gets removed -- both answers applied the same list; the keys
# only decided whether to then ask about each app individually. The prompt was
# therefore pure friction, and it was also fragile: getevent reads /dev/input
# directly, so it behaved differently in a recovery (screen idle) versus the
# Magisk/KernelSU manager (screen live, ~333 touchscreen events/sec starving
# the wait), and any failure left the install hanging on "Waiting for a volume
# key...".
#
# The install is now fully automatic and idempotent:
#   * force list      -> always removed, never asked
#   * optional list   -> always applied, never asked
#   * bundled pkgs/   -> always installed by service.sh at boot

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
REPLACEMENT_WEBVIEW="$MODPATH/system/priv-app/WebView/WebView.apk"

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

  # Read EVERY path, not just the first. An updated system app reports both
  # its original system path and the Play Store update in /data/app; keeping
  # only line 1 meant that when the system path came first, the update was
  # never touched -- the mask hid the system copy while the updated Google
  # app kept running, another way "ALL the Google stuff" survived. Any
  # /data/app hit now uninstalls the package for user 0, which drops the
  # update and disables the system copy in one step. Bundled replacements
  # are never on these lists (tests/test_lists.sh asserts that), so this
  # cannot remove an app this module ships.
  APP_PATHS=$(pm path "$PACKAGE_NAME" 2>/dev/null | sed 's/^package://')
  [ -n "$APP_PATHS" ] || return 0
  case "$APP_PATHS" in
    *"/data/app/"*)
      if pm uninstall --user 0 "$PACKAGE_NAME" >/dev/null 2>&1; then
        ui_print "- Removed updated build of $PACKAGE_NAME (user 0)."
      else
        ui_print "- Failed to remove updated build of $PACKAGE_NAME."
      fi
      return 0 ;;
  esac

  APP_PATH=$(printf '%s\n' "$APP_PATHS" | sed -n '1p')
  APP_PATH_FOLDER=${APP_PATH%/*}

  # APEX modules and core Android settings/overlay infrastructure are outside
  # this app-masker's scope.
  case "$APP_PATH_FOLDER" in
    /apex/*)
      ui_print "- Skipped APEX package $PACKAGE_NAME."
      return 0 ;;
  esac

  APP_NAME=$PACKAGE_NAME
  if [ -n "$AAPT" ]; then
    LABEL=$("$MODPATH/aapt" dump badging "$APP_PATH" 2>/dev/null | sed -n "s/^application-label:'\(.*\)'$/\1/p" | head -n 1)
    [ -n "$LABEL" ] && APP_NAME=$LABEL
  fi

  # Unattended install: every optional package is removed without asking.
  # There is no volume-key prompt here -- see the header note. Only optional
  # (non-forced) packages reach this point at all; force-removed packages
  # return earlier via their own path.

  case "$APP_PATH_FOLDER" in
    /system/*) ;;
    /*) APP_PATH_FOLDER="/system$APP_PATH_FOLDER" ;;
    *) ui_print "- Skipped unknown path $APP_PATH_FOLDER"; return 0 ;;
  esac

  REMOVE="$REMOVE$APP_PATH_FOLDER "
  ui_print "- Systemlessly masked $APP_NAME."
}

ui_print
ui_print "| Unattended install: applying the full removal list, no prompts."

# 0. Futo Keyboard. Pre-install the bundled Futo Keyboard APK so that
#    ensure_keyboard() below can detect and enable it. This runs during
#    customize.sh (not boot service) to guarantee a replacement IME exists
#    before Gboard is removed.
FUTO_APK="$MODPATH/pkgs/29_futo.apk"
if [ -f "$FUTO_APK" ]; then
  if pm install -r "$FUTO_APK" >/dev/null 2>&1; then
    ui_print "- Futo Keyboard pre-installed from bundled APK."
  else
    ui_print "- Could not pre-install Futo Keyboard; Gboard will be kept unless another keyboard is available."
  fi
fi

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

# 3. Optional list. Always applied: the install is unattended and never asks
#    whether to proceed. Force-removed packages were already handled above.
if [ -f "$debloat_list" ]; then
  while IFS= read -r PACKAGE_NAME || [ -n "$PACKAGE_NAME" ]; do
    process_package "$PACKAGE_NAME" false
  done < "$debloat_list"
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

# 5. Actually apply the masks.
#
# process_package() above collected each system app's folder into $REMOVE and
# printed "Systemlessly masked", but for every release until now those paths
# were only written to .lastremove -- a file NOTHING reads. No mask was ever
# created, so no system app was ever removed: every Google app survived the
# install, Google WebView included. This block is what makes removal real.
#
# Magisk and KernelSU honour a file named `.replace` inside a module folder:
# magic mount then mounts an EMPTY directory over the real one, hiding the app
# systemlessly. Removing the module restores it, which is what "systemless"
# is supposed to mean.
MASKED=0
KEPT_SELF=0
for APP in $REMOVE; do
  REL=${APP#/system/}
  DEST="$MODPATH/system/$REL"

  # Never mask a folder this module ships its own APK into. Our bundled
  # replacements (Dialer, Contacts, DeskClock, Messaging, WebView, ...) often
  # live at the SAME path as the stock app they replace; masking there would
  # delete our own APK along with the stock one. Mounting ours over the stock
  # app already achieves the replacement, so skipping is correct.
  if [ -n "$(find "$DEST" -maxdepth 1 -name '*.apk' 2>/dev/null)" ]; then
    KEPT_SELF=$((KEPT_SELF + 1))
    continue
  fi

  mkdir -p "$DEST" 2>/dev/null || continue
  : > "$DEST/.replace"
  MASKED=$((MASKED + 1))
done
ui_print "- Systemless masks applied: $MASKED (skipped folders holding our own APKs: $KEPT_SELF)."

printf '%s\n' "$REMOVE" > "$MODPATH/.lastremove"
ui_print "- Done. Reboot to apply the module."
