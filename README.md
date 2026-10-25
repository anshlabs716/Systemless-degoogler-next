![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. I made this fork for my
**raven (Google Pixel 6 Pro) running DerpFest Android 17**. This v1.0.0 build
uses a reviewed removal list and keeps core services and the Pixel features I
asked to retain.

<div align="center">
  Download the <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/tag/v1.0.1">v1.0.0 release</a>
</div>

If the release still shows the older ZIP, open **Actions → Release Workflow →
Run workflow**, enter `v1.0.1`, and run it. The workflow rebuilds the module
from `main`, replaces the old ZIP asset, and uploads the v1.0.1 ZIP.

### What it does

- Masks only the system apps listed in `bloat_packagelist.txt`; no automatic
  sweep of every Google package.
- Targets Google Play services, GSF, Setup Wizard, Google Text-to-Speech,
  Recorder, Safety Hub, Photos, DeskClock, Calculator, Google Meet, and Google
  Search, along with the other optional apps in the list.
- Preserves Google Camera, Pixel Launcher, Pixel wallpapers, Now Playing /
  Android System Intelligence, IMS, WebView, DocumentsUI, Settings
  Intelligence, phone/contacts/messages/keyboard apps, and other listed core
  services.
- Does not clear app data, uninstall packages through Package Manager, or
  delete user-installed/updated APKs. Updated apps under `/data/app` are
  skipped.

**Setup Wizard is included as a removal candidate.** Removing it can interfere
with first-time setup or setup/recovery flows. This module is configured for a
device that has already completed setup. Disable the module to restore its
system app files.

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

### Installer screenshots

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

These are my personal recommendations for replacing removed Google apps. The module auto-installs most of these on first boot.

| Removed App | Replacement | Link |
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
| Android Auto | AA4MG | [GitHub](https://github.com/sn-00-x/aa4mg) |
| GMS / GSF | microG | [bitgapps.io/extra](https://bitgapps.io/extra.html) |

Auto-installed by this module: F-Droid, Neo Store, Aurora Store, Proton Pass, Ente Photos, Simple Notes Sync, CalcYou, Breezy Weather, Fennec, Koda, Auxio, Vela Maps, Proton Drive, Dicio, RHVoice, Thunderbird, Fossify Dialer, Fossify Contacts, Fossify Messages, PixelBoard, Fossify Clock, Fossify Calendar, Fossify Files, AntennaPod, Moon+ Reader, Fossify Voice Recorder

NOT installed by this module (manual install required):

- microG — [bitgapps.io/extra](https://bitgapps.io/extra.html)
- AA4MG — [GitHub](https://github.com/sn-00-x/aa4mg)

## Not Replaced (Deleted)

YouTube TV, Google Wallet, Google Pay, Google Lens, Google Play Games, Digital Wellbeing, Safety Hub, Google One, Chromecast, Android TV, Google VR, Play Newsstand, Google Fishfood, Google Search (GSA), TalkBack, Print Service, Google Restore, Google Backup, Federated Compute, On-Device Personalization, Ad Services, Partner Setup, Wi-Fi Calling Activation, Switch Access, Accessibility Menu, Verizon MIPS, Hotword Enrollment, Location History, Turbo Adapter, Bookmark Provider, Partner Bookmarks, SDM Diagnostics, Work Setup / DPC, Setup Wizard, One-time Initializer, Emoji Wallpapers, Google Sync Adapters

## Auto-Install

On first boot after module install, all bundled APKs in `pkgs/` are installed automatically (skipped if already present). Install order: stores first (F-Droid → Neo Store → Aurora Store), then all others. Logs written to `/data/adb/modules/<module-id>/log.txt`. Module is idempotent — safe to re-enable.

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
