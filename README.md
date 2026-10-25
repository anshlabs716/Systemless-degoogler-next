![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. I made this fork for my
**raven (Google Pixel 6 Pro) running DerpFest Android 17**. The first build was
too aggressive, so **v1.0.1 is a conservative hotfix**: keep the core services
and Pixel features, and only mask the reviewed optional apps.

<div align="center">
  Grab the latest build from <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/latest">Releases</a>
</div>

### What it does

- Removes only the reviewed system apps in `bloat_packagelist.txt`. It does not
  automatically sweep every installed Google Apps package.
- Preserves Google Play services and Google Services Framework; a separate
  microG installer can handle those core services for your setup.
- Keeps the Pixel features I asked for, including Now Playing / Android System
  Intelligence, Pixel wallpapers and customization, Recorder, Safety Hub,
  Photos, and the Pixel launcher.
- Keeps Google Camera, DocumentsUI, WebView, Settings Intelligence, IMS,
  package installer, extension services, the dialer, contacts, messaging, and
  keyboard.
- Targets the fishfood camera package for removal while protecting the exact
  Google Camera package.

This hotfix does **not** clear app data, run package-manager uninstall commands,
or delete updated/user-installed APKs. Updated apps under `/data/app` are
skipped. Selected system app folders are hidden through Magisk and return when
the module is disabled. Review the package list before installing because
device builds can differ.

### Install

1. Disable the older Systemless DeGoogler module in Magisk and reboot.
2. Install `systemless-degoogler-1.0.1.zip` from Magisk or a compatible recovery.
3. Press Volume Up for the reviewed default list, or Volume Down to choose
   packages one by one.
4. Reboot. Install/configure microG separately if needed.

This fork is configured for raven / DerpFest Android 17. It has not been
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
