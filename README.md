![Systemless DeGoogler](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

# Systemless DeGoogler

Hey, I’m Ansh. This systemless module removes selected Google apps and reviewed OEM-app candidates, then installs alternatives I use. It keeps selected Pixel features and core Android parts, and makes room for a separate microG install.

**v1.0.3 · 23 regular APKs + 8 privileged LineageOS/AOSP + Fossify apps · [Get both ZIPs](https://github.com/anshlabs716/Systemless-degoogler-next/releases)**

> ⚠️ **Warning: I am not liable for any damage caused to your device.** Flash this module at your own risk. Back up your data before installing.

## Contents

- [What it does](#what-it-does)
- [Install](#install)
- [FOSS replacements](#foss-replacements)
- [What’s being removed](#whats-being-removed)
- [Remove Google WebView](#remove-google-webview)
- [Bundled apps and versions](#bundled-apps-and-versions)
- [Canta and Shizuku](#canta-and-shizuku)
- [KernelSU (untested)](#kernelsu-untested)
- [Supported installation formats](#supported-installation-formats)

## What it does

The module only processes package IDs in its reviewed lists; it does not scan the phone or remove every app it finds. The optional list includes Google apps and curated OEM/carrier candidates. The [force list](force_packagelist.txt) contains selected Google apps removed without a per-app prompt.

Google Camera, Pixel Launcher, Pixel Wallpapers, Pixel Customization, and selected Android services and overlays are protected. Samsung Bixby is explicitly protected. Setup Wizard is an optional candidate, so use this module only after initial device setup.

The module does not install microG. Install it separately if needed: [microG setup](https://bitgapps.io/extra.html). PixelBoard requires GMS or microG; Futo Keyboard is bundled as a keyboard option that does not depend on either.

Changes made by the module are systemless. Disable or remove it in Magisk or KernelSU and reboot to restore masked system apps. Back up your data. When the module is removed, its bundled apps are migrated to regular user apps first: they stay installed and become normally uninstallable from Settings.

Removal is applied two ways, because one is not enough on its own: apps still in the system image are hidden with a `.replace` mask (restored when the module is removed), while apps a Play Store update moved into `/data/app` are uninstalled for user 0, since a systemless mask cannot reach them there. Google WebView is replaced by the bundled open-source WebView.

## Install

1. Install `systemless-degoogler-v1.0.3.zip` in the Magisk app, or `systemless-degoogler-v1.0.0-ksu.zip` in KernelSU Manager. Manager apps only.
2. The install is fully unattended: it applies the full removal list (force plus optional) and installs the bundled apps without asking any questions. There are no volume-key prompts.
3. Reboot. Bundled system apps become available as Android finishes booting. The boot service then grants the bundled privileged apps their runtime permissions, so Clock, Etar, Recorder, WebView and the Fossify trio (Phone, Messages, Contacts) behave like the stock apps they replace instead of prompting for permission on first use. Fossify Messages is set as the default SMS app (role, legacy setting and WRITE_SMS appop) and Fossify Phone as the default dialer by the boot service.
4. Install microG separately if you want it.

The module leaves the stock launcher enabled. To hide its search bar, long-press the home screen and turn off the bar in launcher settings.

## FOSS replacements

These are my suggestions. Most are bundled; microG and AA4MG must be installed separately.

| Replaces | App | Link |
|---|---|---|
| Play Store | F-Droid Basic, Neo Store, Aurora Store | [F-Droid](https://f-droid.org/packages/org.fdroid.basic/), [Neo Store](https://github.com/NeoApplications/Neo-Store), [Aurora](https://f-droid.org/packages/com.aurora.store/) |
| Gboard | Futo Keyboard, PixelBoard | [Futo](https://github.com/futo-org/android-keyboard) |
| Chrome | Brave | [GitHub](https://github.com/brave/brave-browser) |
| YouTube | Koda | [GitHub](https://github.com/Ivorisnoob/Koda) |
| google Music | Auxio | [GitHub](https://github.com/OxygenCobalt/Auxio) |
| google Maps | Vela Maps | [GitHub](https://github.com/PimpinPumpkin/Vela) |
| google Photos | Ente Photos | [GitHub](https://github.com/ente-io/ente) |
| Clock, Etar Calendar, Recorder, WebView and the Fossify trio (Phone, Messages, Contacts) | LineageOS/AOSP + Fossify apps (bundled) | [LineageOS](https://github.com/LineageOS), [Fossify](https://github.com/FossifyOrg) |
| Files by Google / document picker and Google Drive file access | Fossify Files (bundled) | [GitHub](https://github.com/FossifyOrg/File-Manager) |
| google Calculator | CalcYou | [GitHub](https://github.com/CalcyYou/CalcYou) |
| Google Assistant/gemini | Dicio | [GitHub](https://github.com/Stypox/Dicio) |
| Google Text-to-speech | RHVoice | [GitHub](https://github.com/RHVoice/RHVoice-Android) |
| Gmail | Thunderbird | [GitHub](https://github.com/thunderbird/thunderbird-android) |
| Google Drive | Proton Drive | [Proton](https://proton.me/drive) |
| Passwords | Proton Pass | [Proton](https://proton.me/pass) |
| Google VPN | Proton VPN | [Proton](https://protonvpn.com/) |
| Google Weather | Breezy Weather | [GitHub](https://github.com/breezy-weather/breezy-weather) |
| Google keep | Simple Notes Sync | [GitHub](https://github.com/SimpleMobileTools/Simple-Notes) |
| Step tracking | MILES, my step tracker | [GitHub](https://github.com/anshlabs716/miles) |
| Quick Share | Bada | [GitHub](https://github.com/kyujin-cho/Bada) |
| --- | NetGuard | [GitHub](https://github.com/M66B/NetGuard) |
| --- | Compass | [GitHub](https://github.com/Kr0oked/Compass) |
| Android Auto | AA4MG (manual install) | [GitHub](https://github.com/sn-00-x/aa4mg) |
| Google Play services | microG (manual install) | [Setup guide](https://bitgapps.io/extra.html) |

Futo Keyboard is bundled and installed with the other regular apps in one pass, before Gboard is masked, so a replacement keyboard is always available. PixelBoard is also bundled as an optional keyboard and requires GMS or microG.

## What’s being removed

The lists cover **374 unique package candidates**: 373 on the optional list (Google/Pixel plus curated OEM/carrier entries) and 15 on the force list, 14 of which repeat from the optional list. A package is affected only if it is present on the phone.

| List | Apps and services |
|---|---|
| Google and Pixel (106 candidates) | Files, Play Games, Assistant, Gmail, Clock, Calculator, Search, TTS, Setup Wizard, Keep, Android Auto, Maps, Weather, Recorder, Safety Hub, Photos, Meet, Play services, Docs, Work setup/DPC, YouTube, Play Store, Chrome, Lens, Movies, Music, TalkBack, Print Service, Backup and Restore, Wallet, Podcasts, Books, Magazines, TV/VR apps, Contacts, Calendar, Phone, Messages, Gboard, Digital Wellbeing, Emoji Wallpapers, Android System Intelligence, Federated Compute, On-device Personalization, Ad Services, Partner Setup, Wi-Fi Calling, Switch Access, Hotword Enrollment, Location History, and related Google services. |
| OEM and carrier (267 candidates) | Curated candidates for Samsung, Xiaomi/Redmi/POCO, OnePlus, Nothing/CMF, Fairphone, Motorola, Sony, Oppo, Vivo, Realme/iQOO, ASUS, Lenovo, Transsion brands, and carriers. Bixby and selected essential components are protected. |
| Force list (15 Google entries) | Gmail, Google Search, Maps, Photos, Pixel Weather, Files by Google, Phone, Contacts, Calendar, Clock, Calculator, Messages, Digital Wellbeing, Google Print Service, and Google WebView (only when the bundled replacement is verified). Gboard is masked only after another keyboard is available. |

The exact package IDs are in [bloat_packagelist.txt](bloat_packagelist.txt) and [force_packagelist.txt](force_packagelist.txt). Google Play services (GMS) is optional; select it for removal when preparing for microG. The module metadata provider (`com.google.android.modulemetadata`) is never removed: system_server parses its APK at startup, and hiding it crashes the phone into a bootloop.

OEM packages vary by model, region, Android version, and ROM. This is a curated list, not a guarantee of complete coverage or a claim that every candidate is safe for every device. Review OEM candidates individually and keep Bixby if you use it.

## Remove Google WebView

The module already removes Google WebView during install: it uninstalls the Play Store update of `com.google.android.webview`, masks the system copy, and removes the Trichrome library packages. The bundled Cromite WebView (`com.android.webview`) takes over as the WebView implementation.

If Play Store ever brings Google WebView back:

1. Settings → Apps → **Android System WebView** → **Uninstall updates** → **Disable**.
2. Or with the phone connected to your computer: `adb shell pm uninstall --user 0 com.google.android.webview`
3. Confirm it is gone: `adb shell pm path com.google.android.webview` — no output means gone.
4. Confirm the bundled one is active: Settings → About phone → tap **Build number** 7 times → back to Settings → System → **Developer options** → **WebView implementation** → it must show the bundled `com.android.webview`.

## Bundled apps and versions

The ZIP contains **23 regular-app APKs** and **8 privileged LineageOS/AOSP + Fossify apps**. The Fossify apps are privileged because they need it: Phone requests CALL_PRIVILEGED to place calls, Messages must be able to serve as the default SMS app, and Files needs All Files Access (MANAGE_EXTERNAL_STORAGE).

Privileged apps (mounted from `system/priv-app` at boot):

| Privileged app | Package ID | Version |
|---|---|---:|
| DeskClock | `com.android.deskclock` | 16 |
| WebView (Cromite) | `com.android.webview` | 153.0.8010.37 |
| Etar Calendar | `org.lineageos.etar` | 14 |
| Recorder | `org.lineageos.recorder` | 16 |
| Fossify Phone | `org.fossify.phone` | 1.11.1 |
| Fossify Messages | `org.fossify.messages` | 1.10.2 |
| Fossify Contacts | `org.fossify.contacts` | 1.6.0 |
| Fossify Files | `org.fossify.filemanager` | 1.6.3 |

Regular apps (installed from `pkgs/` during module install):

| Regular app | Package ID | Version |
|---|---|---:|
| F-Droid Basic | `org.fdroid.basic` | 2.0.2 |
| Neo Store | `com.machiav3lli.fdroid` | 1.3.2 |
| Aurora Store | `com.aurora.store` | 4.8.4 |
| Proton VPN | `ch.protonvpn.android.reproducible` | 5.20.98.0 |
| Proton Pass (F-Droid) | `proton.android.pass.fdroid` | 1.41.4 |
| Ente Photos | `io.ente.photos.fdroid` | 1.3.66 |
| Simple Notes Sync | `dev.dettmer.simplenotes` | 2.20.1 |
| CalcYou | `net.youapps.calcyou` | 5.3 |
| Breezy Weather | `org.breezyweather` | 6.2.2_freenet |
| Brave | `com.brave.browser` | 1.78.97 |
| Koda | `com.ivor.ivormusic` | 5.2 |
| Auxio | `org.oxycblt.auxio` | 4.1.5 |
| Vela Maps | `app.vela` | 0.5.2621 |
| Proton Drive | `me.proton.android.drive` | 3.2.0 |
| Dicio | `org.stypox.dicio` | 4.2 |
| RHVoice | `com.github.olga_yakovleva.rhvoice.android` | 1.18.4 |
| Thunderbird | `net.thunderbird.android` | 24.0 |
| Bada | `dev.bluehouse.bada` | 20261007.01 |
| NetGuard | `dev.ukanth.ufirewall` | 5.0.0-BETA_1 |
| Compass | `com.bobek.compass` | 2.2.0 |
| Futo Keyboard | `org.futo.inputmethod.latin` | 0.1.30 |
| PixelBoard (optional, needs GMS/microG) | `com.akshaykadam.pixelboard` | 18.5.3 |
| MILES | `com.anshlabs.miles` | 1.1.6 |

All 23 regular APKs install in a single pass during module install, before Gboard is masked (Futo Keyboard included). PixelBoard is included as an optional keyboard and requires GMS or microG. Already-installed regular apps are skipped. See [pkgs/README.md](pkgs/README.md) for the APK file paths. The install log is `/data/adb/modules/systemless-degoogler/log.txt`. microG and AA4MG are not bundled.

## Canta and Shizuku

For non-Google bloat on an OEM build or custom ROM, you can use Canta with Shizuku to review and remove additional installed apps. **Neither tool is bundled or required.**

- [Canta on F-Droid](https://f-droid.org/packages/io.github.samolego.canta/) · [Canta project](https://github.com/samolego/Canta)
- [Shizuku download](https://shizuku.rikka.app/download/) · [Shizuku project](https://github.com/RikkaApps/Shizuku)

Canta uses Shizuku to manage installed packages. Review each action carefully: OEM apps may provide device features, and removals made with Canta are separate from this module. Disabling this module will not undo Canta's changes.

## KernelSU (untested)

The `systemless-degoogler-v1.0.0-ksu.zip` build is **untested on a device**. Install it through KernelSU Manager only. It requires an enabled compatible system metamodule, such as [meta-overlayfs](https://github.com/tiann/KernelSU/releases).

## Supported installation formats

This project intentionally supports **manager-installed systemless modules only**:

- **Magisk:** install the Magisk ZIP through the Magisk app.
- **KernelSU:** install the KernelSU ZIP through KernelSU Manager (device testing is still marked untested above).

**Recovery install is not added and will not be added:** it is too risky (a failed flash can lose your data or leave the device unbootable), and the hardware available for this project is not good enough to build and test it safely. The `META-INF/com/google/android/` files inside the package are the standard Magisk module installer entrypoints and are required for Magisk app installation.


---

## 📁 Project Files

```text
Systemless-degoogler-next/
├── .github/
│   └── workflows/
│       └── release.yml
├── .gitignore
├── bloat_packagelist.txt
├── build.sh
├── customize.sh
├── force_packagelist.txt
├── LICENSE
├── META-INF/
│   └── com/
│       └── google/
├── module.prop
├── pkgs/
│   └── README.md
├── README.md
├── Screenshots/
│   ├── Installation/
│   │   ├── Custom.jpg
│   │   ├── Default-1.jpg
│   │   ├── Default-2.jpg
│   │   └── Waiting.jpg
│   ├── MIUI10/
│   │   ├── 1.jpg
│   │   └── 2.jpg
│   ├── MIUI11/
│   │   ├── 1.jpg
│   │   └── 2.jpg
│   └── MIUI12.5/
│       ├── 1.jpg
│       └── 2.jpg
├── service.sh
├── system/
│   └── etc/
│       └── permissions/
└── tests/
    ├── gen-privapp-allowlist.sh
    ├── test_lists.sh
    ├── test_unattended.sh
    └── verify-apk.sh
```

---

