![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. This v1.0.1 build is a
systemless degoogler ZIP intended to make way for a separate microG install
and to install alternative apps when their APKs are bundled. It keeps selected
Pixel features and essential Android components.

<div align="center">
  Download the <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/tag/v1.0.1">v1.0.1 release</a>
</div>

## Table of Contents

- [What it does](#what-it-does)
- [Install](#install)
- [FOSS Replacements](#foss-replacements)
- [Not Replaced (Deleted)](#not-replaced-deleted)
- [Auto-Install](#auto-install)
- [Recovery ZIP](#recovery-zip)
- [Installer screenshots](#installer-screenshots)

### What it does

- Masks only the reviewed packages listed in `bloat_packagelist.txt`; it does not sweep the Google package namespace.
- Removes selected Google apps and services, including Contacts, Calendar, Phone, Messages, Gboard, Digital Wellbeing, Emoji Wallpapers, and the other listed packages.
- Keeps Google Wallpapers, Pixel Customization, Google Camera, Pixel Launcher, and essential Android services, settings providers, and overlays.
- Does not clear app data, uninstall packages through Package Manager, or delete updated/user-installed APKs. Updated apps under `/data/app` and APEX components are skipped.
- Installs numbered APKs found in `pkgs/` after Android finishes booting. Already installed apps are skipped; results are logged.

**Setup Wizard is included as a removal candidate.** Removing it can interfere
with first-time setup or setup/recovery flows. This module is intended for a
device that has already completed setup.

**Undo warning:** this module masks system apps through Magisk. Disable or
remove the module and reboot to restore the masked system apps. If you manually
delete system files or modify the ROM outside this module, you may need to
reflash the ROM to restore them. Keep a backup and a working recovery route.

The module prepares for a separate microG installation; it does not install
microG itself. Review the package list before installing, since DerpFest builds
can differ.

### Install

1. Install the ZIP from Magisk or a compatible recovery.
2. Press Volume Up for the listed default removals, or Volume Down to choose
   packages one by one.
3. Reboot. Install/configure microG separately if needed.

This fork is configured for raven / DerpFest Android 17 and has not been
verified on-device. Keep a recovery route handy and make a backup first.

### Recovery ZIP\n\nA dedicated recovery-flashable ZIP is coming soon.\n\n## Installer screenshots

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
| — | F-Droid | [f-droid.org](https://f-droid.org/) |
| — | Neo Store | [GitHub](https://github.com/NeoApplications/Neo-Store) |
| Google Play Store | Aurora Store | [F-Droid](https://f-droid.org/packages/com.aurora.store/) |
| Google Passwords | Proton Pass | [F-Droid](https://f-droid.org/packages/proton.android.pass.fdroid/) |
| Google Photos | Ente Photos | [F-Droid](https://f-droid.org/packages/io.ente.photos/) |
| Google Keep | Simple Notes Sync | [F-Droid](https://f-droid.org/packages/dev.dettmer.simplenotes/) |
| Google Calculator | CalcYou | [F-Droid](https://f-droid.org/packages/net.youapps.calcyou/) |
| Google Weather | Breezy Weather | [F-Droid](https://f-droid.org/packages/org.breezyweather/) |
| Chrome | Fennec | [F-Droid](https://f-droid.org/packages/org.mozilla.fennec_fdroid/) |
| YouTube | Koda | [GitHub](https://github.com/Ivorisnoob/Koda) |
| Google Music | Auxio | [F-Droid](https://f-droid.org/packages/org.oxycblt.auxio/) |
| Google Maps | Vela Maps | [GitHub](https://github.com/PimpinPumpkin/Vela) |
| Google Drive | Proton Drive | [F-Droid](https://f-droid.org/) |
| Google Docs | Proton Drive | [F-Droid](https://f-droid.org/) |
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
| Google Podcasts | AntennaPod | [F-Droid](https://f-droid.org/packages/de.danoeh.antennapod/) |
| Google Books | Moon+ Reader | [F-Droid](https://f-droid.org/) |
| Google Recorder | Fossify Voice Recorder | [F-Droid](https://f-droid.org/packages/org.fossify.voicerecorder/) |
| Google Fit / step tracking | MILES (my step tracker) | [GitHub](https://github.com/anshlabs716/miles/releases) |
| Android Auto | AA4MG | [GitHub](https://github.com/sn-00-x/aa4mg) |
| GMS / GSF | microG | [bitgapps.io/extra](https://bitgapps.io/extra.html) |

Auto-installed by this module: F-Droid, Neo Store, Aurora Store, Proton Pass, Ente Photos, Simple Notes Sync, CalcYou, Breezy Weather, Fennec, Koda, Auxio, Vela Maps, Proton Drive, Dicio, RHVoice, Thunderbird, Fossify Dialer, Fossify Contacts, Fossify Messages, PixelBoard, Fossify Clock, Fossify Calendar, Fossify Files, AntennaPod, Moon+ Reader, Fossify Voice Recorder

NOT installed by this module (manual install required):

- microG — [bitgapps.io/extra](https://bitgapps.io/extra.html)
- AA4MG — [GitHub](https://github.com/sn-00-x/aa4mg)

## Not Replaced (Deleted)

YouTube TV, Google Wallet, Google Pay, Google Lens, Google Play Games, Digital Wellbeing, Safety Hub, Google One, Chromecast, Android TV, Google VR, Play Newsstand, Google Fishfood, Google Search (GSA), TalkBack, Print Service, Google Restore, Google Backup, Federated Compute, On-Device Personalization, Ad Services, Partner Setup, Wi-Fi Calling Activation, Switch Access, Accessibility Menu, Verizon MIPS, Hotword Enrollment, Location History, Turbo Adapter, Bookmark Provider, Partner Bookmarks, SDM Diagnostics, Work Setup / DPC, Setup Wizard, One-time Initializer, Emoji Wallpapers, Google Sync Adapters

Google Wallpapers and Pixel Customization are kept by the module.

## Auto-Install

On first boot after module install, APKs in `pkgs/` are installed in filename order, with the three app stores first. Already installed packages are skipped. Logs are written to `/data/adb/modules/<module-id>/log.txt`, and the installer can safely run again after reboot.

**APK bundle status:** The installer is implemented, but the repository currently has no replacement APK binaries in `pkgs/`. The listed apps will not be installed until those APK files are added.

Bundle these APKs in `pkgs/` (numbered for install order):

```text
01_fdroid.apk
02_neostore.apk
03_aurora.apk
04_protonpass.apk
05_ente.apk
06_simplenotes.apk
07_calcyou.apk
08_breezy.apk
09_fennec.apk
10_koda.apk
11_auxio.apk
12_vela.apk
13_protondrive.apk
14_dicio.apk
15_rhvoice.apk
16_thunderbird.apk
17_fossifydialer.apk
18_fossifycontacts.apk
19_fossifymessages.apk
20_pixelboard.apk
21_fossifyclock.apk
22_fossifycalendar.apk
23_fossifyfiles.apk
24_antennapod.apk
25_moonreader.apk
26_fossifyvoicerecorder.apk
```

Do NOT bundle or install microG or AA4MG. They are link-only in the README (manual install).
