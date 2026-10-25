![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone with a reversible Magisk module

This fork adapts Systemless DeGoogler for a microG setup and the author's
**DerpFest Android 17 build on raven (Google Pixel 6 Pro)**. It keeps the
original project's visual style and installer screenshots while documenting
this fork's actual package rules.

<div align="center">
  Download the latest build from <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/latest">Releases</a>
</div>

### Configured target

- Device: `raven` (Google Pixel 6 Pro)
- ROM: DerpFest Android 17
- Scope: configuration target; runtime installation on this device has not been verified.

### What this fork does

- Removes the optional Google apps listed in `bloat_packagelist.txt`.
- Adds installed `com.google.android.apps.*` packages at install time so DerpFest build differences are covered.
- Removes Google Play services and Google Services Framework for a microG setup. **This module does not install microG**; install and configure microG separately.
- Keeps the requested Pixel features, including Android System Intelligence / Now Playing, Pixel wallpapers and customization, Recorder, Safety Hub, Photos, and the Pixel launcher.
- Keeps Google Camera, DocumentsUI, WebView, Settings Intelligence, IMS, package installer, extension services, and extension shared library.
- Targets the fishfood camera package for removal while keeping the exact Google Camera package above.

The installer supports the default removal set or a volume-key customization flow. It clears app-private data for each package selected for removal. For updated or data-installed copies, it also attempts to uninstall the package for the primary Android user. **Cleared app data cannot be restored by disabling the module.**

System apps are hidden systemlessly through the Magisk module. Disabling the module restores hidden system app files, but does not restore cleared app data. Apps not found on the phone are skipped.

### Install

1. Install the ZIP from the Magisk app or a compatible recovery.
2. Choose the default configuration with Volume Up, or choose packages interactively with Volume Down.
3. Reboot after installation.
4. Install/configure microG separately if needed by your ROM and signature-spoofing setup.

Keep a recovery path available before changing system apps. This fork is configured for raven/DerpFest Android 17; other ROMs and devices are not claimed as tested.

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
