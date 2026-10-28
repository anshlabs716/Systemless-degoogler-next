![Systemless DeGoogler](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

# Systemless DeGoogler

Hey, I’m Ansh. This systemless module removes selected Google apps and reviewed OEM-app candidates, then installs alternatives I use. It keeps selected Pixel features and core Android parts, and makes room for a separate microG install.

**v1.0.3 · 29 bundled APKs · [Get both ZIPs](https://github.com/anshlabs716/Systemless-degoogler-next/releases)**

## Contents

- [What it does](#what-it-does)
- [Install](#install)
- [FOSS replacements](#foss-replacements)
- [What’s being removed](#whats-being-removed)
- [Auto-installed apps](#auto-installed-apps)
- [Canta and Shizuku](#canta-and-shizuku)
- [KernelSU (untested)](#kernelsu-untested)
- [Recovery ZIP](#recovery-zip)

## What it does

The module only processes package IDs in its reviewed lists; it does not scan the phone or remove every app it finds. The optional list includes Google apps and curated OEM/carrier candidates. The [force list](force_packagelist.txt) contains selected Google apps removed without a per-app prompt.

Google Camera, Pixel Launcher, Pixel Wallpapers, Pixel Customization, and selected Android services and overlays are protected. Samsung Bixby is explicitly protected. Setup Wizard is an optional candidate, so use this module only after initial device setup.

The module does not install microG. Install it separately if needed: [microG setup](https://bitgapps.io/extra.html). PixelBoard requires GMS or microG; Futo Keyboard is bundled as a keyboard option that does not depend on either.

Changes made by the module are systemless. Disable or remove it in Magisk or KernelSU and reboot to restore masked system apps. Back up your data and keep a recovery route available.

## Install

1. Install `systemless-degoogler-v1.0.3.zip` in the Magisk app, or `systemless-degoogler-v1.0.0-ksu.zip` in KernelSU Manager. Do not flash the KernelSU ZIP from recovery.
2. Installing from Magisk Manager cannot receive interactive volume-key input, so it leaves the optional list unchanged and applies only the force list. To choose optional apps with volume keys, install the ZIP from custom recovery: Volume Up selects the full list; Volume Down reviews candidates individually.
3. Reboot. Bundled apps are installed after Android finishes booting.
4. Install microG separately if you want it.

The module leaves the stock launcher enabled. To hide its search bar, long-press the home screen and turn off the bar in launcher settings.

## FOSS replacements

These are my suggestions. Most are bundled; microG and AA4MG must be installed separately.

| Replaces | App | Link |
|---|---|---|
| Play Store | F-Droid Basic, Neo Store, Aurora Store | [F-Droid](https://f-droid.org/packages/org.fdroid.basic/), [Neo Store](https://github.com/NeoApplications/Neo-Store), [Aurora](https://f-droid.org/packages/com.aurora.store/) |
| Gboard | Futo Keyboard | [GitHub](https://github.com/futo-org/android-keyboard) |
| Chrome | Brave | [GitHub](https://github.com/brave/brave-browser) |
| YouTube | Koda | [GitHub](https://github.com/Ivorisnoob/Koda) |
| Music | Auxio | [GitHub](https://github.com/OxygenCobalt/Auxio) |
| Maps | Vela Maps | [GitHub](https://github.com/PimpinPumpkin/Vela) |
| Photos | Ente Photos | [GitHub](https://github.com/ente-io/ente) |
| Phone, contacts, messages, calendar, clock, files, recorder | Fossify apps | [Fossify](https://github.com/FossifyOrg) |
| Calculator | CalcYou | [GitHub](https://github.com/CalcyYou/CalcYou) |
| Assistant | Dicio | [GitHub](https://github.com/Stypox/Dicio) |
| Text-to-speech | RHVoice | [GitHub](https://github.com/RHVoice/RHVoice-Android) |
| Email | Thunderbird | [GitHub](https://github.com/thunderbird/thunderbird-android) |
| Drive | Proton Drive | [Proton](https://proton.me/drive) |
| Passwords | Proton Pass | [Proton](https://proton.me/pass) |
| Google VPN | Proton VPN | [Proton](https://protonvpn.com/) |
| Weather | Breezy Weather | [GitHub](https://github.com/breezy-weather/breezy-weather) |
| Notes | Simple Notes Sync | [GitHub](https://github.com/SimpleMobileTools/Simple-Notes) |
| Step tracking | MILES, my step tracker | [GitHub](https://github.com/anshlabs716/miles) |
| Quick Share | Bada | [GitHub](https://github.com/kyujin-cho/Bada) |
| Firewall | NetGuard | [GitHub](https://github.com/M66B/NetGuard) |
| Compass | Compass | [GitHub](https://github.com/Kr0oked/Compass) |
| Android Auto | AA4MG (manual install) | [GitHub](https://github.com/sn-00-x/aa4mg) |
| Google Play services | microG (manual install) | [Setup guide](https://bitgapps.io/extra.html) |

Futo Keyboard is bundled so a replacement is available if Gboard is removed. If Futo cannot be pre-installed and no other keyboard is available, the installer keeps Gboard. PixelBoard is another option, but requires GMS or microG.

## What’s being removed

The lists cover **332 unique package candidates**: 67 Google/Pixel entries and 265 OEM/carrier entries. The force list repeats 14 Google entries from the optional list, so it adds no new package IDs. A package is affected only if it is present on the phone.

| List | Apps and services |
|---|---|
| Google and Pixel (67 candidates) | Files, Play Games, Assistant, Gmail, Clock, Calculator, Search, TTS, Setup Wizard, Keep, Android Auto, Maps, Weather, Recorder, Safety Hub, Photos, Meet, Play services, Docs, Work setup/DPC, YouTube, Play Store, Chrome, Lens, Movies, Music, TalkBack, Print Service, Backup and Restore, Wallet, Podcasts, Books, Magazines, TV/VR apps, Contacts, Calendar, Phone, Messages, Gboard, Digital Wellbeing, Emoji Wallpapers, Android System Intelligence, Federated Compute, On-device Personalization, Ad Services, Partner Setup, Wi-Fi Calling, Switch Access, Hotword Enrollment, Location History, and related Google services. |
| OEM and carrier (265 candidates) | Curated candidates for Samsung, Xiaomi/Redmi/POCO, OnePlus, Nothing/CMF, Fairphone, Motorola, Sony, Oppo, Vivo, Realme/iQOO, ASUS, Lenovo, Transsion brands, and carriers. Bixby and selected essential components are protected. |
| Force list (14 Google entries) | Gmail, Google Search, Maps, Photos, Pixel Weather, Files by Google, Phone, Contacts, Calendar, Clock, Calculator, Messages, Digital Wellbeing, and Google Print Service. Gboard is masked only after another keyboard is available. |

The exact package IDs are in [bloat_packagelist.txt](bloat_packagelist.txt) and [force_packagelist.txt](force_packagelist.txt). Google Play services (GMS) is optional; select it for removal when preparing for microG.

OEM packages vary by model, region, Android version, and ROM. This is a curated list, not a guarantee of complete coverage or a claim that every candidate is safe for every device. Review OEM candidates individually and keep Bixby if you use it.

## Auto-installed apps

The ZIP contains **29 APKs**, numbered consecutively `01`–`29`. Futo Keyboard is `29_futo.apk`; it is included to provide a keyboard option if Gboard is removed. Already-installed packages are skipped. The install log is `/data/adb/modules/systemless-degoogler/log.txt`.

See [pkgs/README.md](pkgs/README.md) for the complete numbered inventory. microG and AA4MG are not bundled.

## Canta and Shizuku

For non-Google bloat on an OEM build or custom ROM, you can use Canta with Shizuku to review and remove additional installed apps. **Neither tool is bundled or required.**

- [Canta on F-Droid](https://f-droid.org/packages/io.github.samolego.canta/) · [Canta project](https://github.com/samolego/Canta)
- [Shizuku download](https://shizuku.rikka.app/download/) · [Shizuku project](https://github.com/RikkaApps/Shizuku)

Canta uses Shizuku to manage installed packages. Review each action carefully: OEM apps may provide device features, and removals made with Canta are separate from this module. Disabling this module will not undo Canta's changes.

## KernelSU (untested)

The `systemless-degoogler-v1.0.0-ksu.zip` build is **untested on a device**. Install it through KernelSU Manager, not custom recovery. It requires an enabled compatible system metamodule, such as [meta-overlayfs](https://github.com/tiann/KernelSU/releases).

## Recovery ZIP

A recovery-flashable degoogling ZIP is planned for a **separate repository** with separate tooling. The ZIPs here are Magisk and KernelSU module packages. The Magisk package’s `META-INF/` files are module installer files; they are not the separate recovery ZIP.
