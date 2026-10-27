![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. The newest build, v1.0.2, is a
systemless degoogler ZIP intended to make way for a separate microG install
and to install alternative apps when their APKs are bundled. It keeps selected
Pixel features and essential Android components.

<div align="center">
  Newest build: <strong>v1.0.2</strong>. The <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases">published Releases page</a> is unchanged.
</div>

## Table of Contents

- [What it does](#what-it-does)
- [Install](#install)
- [FOSS Replacements](#foss-replacements)
- [Not Replaced (Deleted)](#not-replaced-deleted)
- [Auto-Install](#auto-install)
- [KernelSU / APatch](#kernelsu--apatch)
- [Recovery ZIP](#recovery-zip)
- [Installer screenshots](#installer-screenshots)

### What it does

- Masks only the reviewed packages listed in `bloat_packagelist.txt`; it does not sweep the Google package namespace.
  
- Targets reviewed Google related bloat only. It does not remove device specific bloat packages.

- Keeps Google Wallpapers, Pixel Customization, Google Camera, Pixel Launcher, and essential Android services, settings providers, and overlays.

- Keeps the stock launcher installed, enabled and default. This module never disables or replaces a home app — deleting a launcher will always leave you with a working home screen. The Google search bar, mic and Lens icons are drawn by the stock launcher itself, so they stay; that is the trade for a home screen that can't be bricked.

- Removes the listed preinstalled Google apps and services—including GMS, Play Store, Gmail, Search, Maps, Photos, Contacts, Calendar, Phone, Messages, and Gboard—to make way for microG. Apps you installed or updated yourself are left alone.

- Installs numbered APKs found in `pkgs/` after Android finishes booting. Already installed apps are skipped; results are logged.

**Setup Wizard is included as a removal candidate.** Removing it can interfere
with first-time setup or setup/recovery flows. This module is intended for a
device that has already completed setup (but in the recovery zip which is coming soon all the setup services will be there so dont worry)

Bada is bundled as an alternative to Quick Share. If you do not want it, uninstall it normally.

**Undoing the changes:** Disable or remove the module in Magisk and reboot to restore the stock system apps it masked. Magisk Safe Mode turns modules off temporarily, so those Google apps can reappear until the module is enabled again.

The module prepares for a separate microG installation; it does not install
microG itself. Review the package list before installing, since DerpFest builds
can differ.

### Install

1. Install the ZIP from Magisk (KernelSU and APatch support coming soon).
2. Press Volume Up for the listed default removals, or Volume Down to choose
   packages one by one.
3. Reboot. Install/configure microG separately if needed.

## KernelSU / APatch

**Coming soon.** The module already uses the portable bits — it builds a
`REMOVE` list that both Magisk and KernelSU consume to create whiteouts, and it
ships the usual sourced `customize.sh` plus a `service.sh` late-start script, so
the format itself ports over cleanly.

What still needs doing before it is honest to call it supported:

- Detect KernelSU / APatch (`$KSU`, `$APATCH`) instead of assuming Magisk.
- Refuse to install silently when KernelSU has no metamodule. KernelSU mounts
  `system/` through a pluggable metamodule such as `meta-overlayfs`, and without
  one the whiteouts are written but nothing ever mounts — the debloat would do
  nothing with no error at all.
- Fix the install instructions above: KernelSU modules cannot be flashed from
  custom recovery, only from the KernelSU manager.

Untested on KernelSU and APatch today. Keep a recovery route handy.

This fork is intended for people who really want that custom rom but its google only (yeah i know Ive been there) and has not been verified on-device. Keep a recovery route handy and make a backup first or use magisk recovery)

## Recovery ZIP

A dedicated recovery-flashable ZIP is coming soon (don't worry the recovery zip coming soon will NOT contain the setup services)

## Installer screenshots

<details>
  <summary>Original project installer screenshots</summary>

  <img src="Screenshots/Installation/Waiting.jpg" width="25%">
  <img src="Screenshots/Installation/Default-1.jpg" width="25%">
  <img src="Screenshots/Installation/Default-2.jpg" width="25%">
  <img src="Screenshots/Installation/Custom.jpg" width="25%">
</details>

<details>
  <summary>Original project device screenshots (historical, not tests of this fork)</summary>

  <p>MIUI 10</p>
  <img src="Screenshots/MIUI10/1.jpg" width="25%">
  <img src="Screenshots/MIUI10/2.jpg" width="25%">

  <p>MIUI 11</p>
  <img src="Screenshots/MIUI11/1.jpg" width="25%">
  <img src="Screenshots/MIUI11/2.jpg" width="25%">

  <p>MIUI 12.5</p>
  <img src="Screenshots/MIUI12.5/1.jpg" width="25%">
  <img src="Screenshots/MIUI12.5/2.jpg" width="25%">
</details>


## FOSS Replacements

These are my recommended alternatives for replacing Google apps and services. Apps are installed on first boot only when their APKs are included in `pkgs/`; microG and AA4MG are manual installs.

| Removed App | My Recommended Replacement | Link |
|---|---|---|
| Google Play Store | F-Droid Basic | [F-Droid](https://f-droid.org/packages/org.fdroid.basic/) |
| Google Play Store | Neo Store | [GitHub](https://github.com/NeoApplications/Neo-Store) |
| Google Play Store | Aurora Store | [F-Droid](https://f-droid.org/packages/com.aurora.store/) |
| Google Fi VPN | Proton VPN | [F-Droid](https://f-droid.org/packages/ch.protonvpn.android.reproducible/) |
| Google Passwords | Proton Pass | [Proton](https://proton.me/pass/download/android) |
| Google Photos | Ente Photos | [F-Droid](https://f-droid.org/packages/io.ente.photos.fdroid/) |
| Google Keep | Simple Notes Sync | [F-Droid](https://f-droid.org/packages/dev.dettmer.simplenotes/) |
| Google Calculator | CalcYou | [F-Droid](https://f-droid.org/packages/net.youapps.calcyou/) |
| Google Weather | Breezy Weather | [F-Droid](https://f-droid.org/packages/org.breezyweather/) |
| Chrome | Brave | [GitHub](https://github.com/brave/brave-browser/releases) |
| YouTube | Koda | [GitHub](https://github.com/Ivorisnoob/Koda) |
| Google Music | Auxio | [F-Droid](https://f-droid.org/packages/org.oxycblt.auxio/) |
| Google Maps | Vela Maps | [GitHub](https://github.com/PimpinPumpkin/Vela) |
| Google Drive | Proton Drive | [Proton APK](https://proton.me/drive/download) |
| Google Docs | Proton Drive | [Proton APK](https://proton.me/drive/download) |
| Google Assistant | Dicio | [F-Droid](https://f-droid.org/packages/org.stypox.dicio/) |
| Google TTS | RHVoice | [F-Droid](https://f-droid.org/packages/com.github.olga_yakovleva.rhvoice.android/) |
| Gmail | Thunderbird | [F-Droid](https://f-droid.org/packages/net.thunderbird.android/) |
| Google Dialer | Fossify Dialer | [F-Droid](https://f-droid.org/packages/org.fossify.phone/) |
| Google Contacts | Fossify Contacts | [F-Droid](https://f-droid.org/packages/org.fossify.contacts/) |
| Google Messages | Fossify Messages | [F-Droid](https://f-droid.org/packages/org.fossify.messages/) |
| Gboard | PixelBoard | [GitHub](https://github.com/Akshayykadam/PixelBoard/releases) |
| Google Clock | Fossify Clock | [F-Droid](https://f-droid.org/packages/org.fossify.clock/) |
| Google Calendar | Fossify Calendar | [F-Droid](https://f-droid.org/packages/org.fossify.calendar/) |
| Files by Google | Fossify Files | [F-Droid](https://f-droid.org/packages/org.fossify.filemanager/) |
| Google Recorder | Fossify Voice Recorder | [F-Droid](https://f-droid.org/packages/org.fossify.voicerecorder/) |
| Google Fit / step tracking | MILES (my step tracker) | [GitHub](https://github.com/anshlabs716/miles/releases) |
| Android Auto | AA4MG | [GitHub](https://github.com/sn-00-x/aa4mg) |
| Google Play services (GMS) | microG | [bitgapps.io/extra](https://bitgapps.io/extra.html) |
| Quick Share | Bada | [GitHub](https://github.com/kyujin-cho/Bada) |
| — | Compass | [GitHub](https://github.com/Kr0oked/Compass) |
| — | NetGuard | [F-Droid](https://f-droid.org/packages/eu.faircode.netguard/) |

Bundled in the rebuilt ZIP: F-Droid Basic, Neo Store, Aurora Store, Proton VPN, Proton Pass, Ente Photos, Simple Notes Sync, CalcYou, Breezy Weather, Brave, Koda, Auxio, Vela Maps, Proton Drive, Dicio, RHVoice, Thunderbird, Fossify Dialer, Fossify Contacts, Fossify Messages, PixelBoard, Fossify Clock, Fossify Calendar, Fossify Files, Fossify Voice Recorder, MILES (my step tracker)

NOT installed by this module (manual install required):

- microG — [bitgapps.io/extra](https://bitgapps.io/extra.html)
- AA4MG — [GitHub](https://github.com/sn-00-x/aa4mg)

## Not Replaced (Deleted)

YouTube TV, Google Wallet, Google Pay, Google Lens, Google Play Games, Digital Wellbeing, Safety Hub, Google One, Chromecast, Android TV, Google VR, Play Newsstand, Google Fishfood, Google Search (GSA), TalkBack, Print Service, Google Restore, Google Backup, Federated Compute, On-Device Personalization, Ad Services, Partner Setup, Wi-Fi Calling Activation, Switch Access, Accessibility Menu, Verizon MIPS, Hotword Enrollment, Location History, Turbo Adapter, Bookmark Provider, Partner Bookmarks, SDM Diagnostics, Work Setup / DPC, Setup Wizard, One-time Initializer, Emoji Wallpapers, Google Sync Adapters

Google Wallpapers and Pixel Customization are kept by the module.

## Auto-Install

On first boot after module install, APKs in `pkgs/` are installed in filename order, with the three app stores first. Already installed packages are skipped. Logs are written to `/data/adb/modules/<module-id>/log.txt`, and the installer can safely run again after reboot.

**Newest build:** v1.0.2. The local ZIP includes the APKs listed below; published release assets are unchanged.

Included APKs in `pkgs/` (numbered for install order):

```text
01_fdroid.apk
02_neostore.apk
03_aurora.apk
04_protonvpn.apk
05_protonpass.apk
06_ente.apk
07_simplenotes.apk
08_calcyou.apk
09_breezy.apk
10_brave.apk
11_koda.apk
12_auxio.apk
13_vela.apk
14_protondrive.apk
15_dicio.apk
16_rhvoice.apk
17_thunderbird.apk
18_fossifydialer.apk
19_fossifycontacts.apk
20_fossifymessages.apk
21_pixelboard.apk
22_fossifyclock.apk
23_fossifycalendar.apk
24_fossifyfiles.apk
25_fossifyvoicerecorder.apk
26_miles.apk
27_bada.apk
28_netguard.apk
29_compass.apk
```

 We do NOT bundle or install microG or AA4MG. They are link-only in the README (manual install).
