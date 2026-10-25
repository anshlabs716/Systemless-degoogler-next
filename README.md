![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. I made this fork for my
**raven (Google Pixel 6 Pro) running DerpFest Android 17**. This v1.0.0 build
uses a reviewed removal list and keeps core services and the Pixel features I
asked to retain.

<div align="center">
  Download the <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/tag/v1.0.0">v1.0.0 release</a>
</div>

### What it does

- Masks only the system apps listed in `bloat_packagelist.txt`; no automatic
  sweep of every Google package.
- Targets Google Play services, GSF, Setup Wizard, Google Text-to-Speech,
  Recorder, Safety Hub, Photos, DeskClock, Calculator, Google Meet, and Google
  Search, along with the other optional apps in the list.
- Preserves the Google Camera app, Pixel Launcher, Pixel wallpapers, Now
  Playing / Android System Intelligence, IMS, WebView, DocumentsUI, Settings
  Intelligence, the phone/contacts/messages/keyboard apps, and other listed
  core services.
- Does not clear app data, uninstall packages through Package Manager, or
  delete user-installed/updated APKs. Updated apps under `/data/app` are
  skipped.

**Setup Wizard is included as a removal candidate.** Removing it can interfere
with first-time setup or recovery/setup flows. This module is configured for a
device that has already completed setup. Disable the module to restore the
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
