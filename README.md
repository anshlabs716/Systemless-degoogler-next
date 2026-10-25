![Logo](https://github.com/Systemless-DeBloaters/Systemless_DeGoogler/assets/76901932/235a1606-e955-452a-8894-0e3a67f8f5b7)

### DeGoogle your phone; keep the Pixel bits you actually like

Hey, I’m Ansh, and this is my first Magisk module. I made this fork for my
**raven (Google Pixel 6 Pro) running DerpFest Android 17**. The goal: make room
for microG without tossing the Pixel features I still use. It’s a personal
project, so think “carefully configured” rather than “tested on every phone
under the sun.”

<div align="center">
  Grab the latest build from <a href="https://github.com/anshlabs716/Systemless-degoogler-next/releases/latest">Releases</a>
</div>

### What it does

- Removes the optional Google apps in `bloat_packagelist.txt`, plus installed
  `com.google.android.apps.*` apps the static list might have missed.
- Removes Google Play services and Google Services Framework to prepare for
  microG. **microG itself is not included**; it needs to be installed and
  configured separately.
- Keeps the Pixel features I asked for, including Now Playing / Android System
  Intelligence, Pixel wallpapers and customization, Recorder, Safety Hub,
  Photos, and the Pixel launcher.
- Keeps Google Camera, DocumentsUI, WebView, Settings Intelligence, IMS,
  package installer, extension services, and the extension shared library.
- Removes the fishfood camera package while keeping the exact Google Camera
  package. Camera package names are a tiny maze; the keep rules are explicit.

### A couple of honest notes

The default install clears app data for each package it removes. For apps
updated or installed under `/data/app`, it also tries to uninstall them for
the primary Android user. That data cleanup is permanent, even if you later
disable the module.

System apps are hidden through Magisk, so disabling the module restores their
system files. Apps that aren’t present are skipped. This fork is configured
for raven / DerpFest Android 17; I haven’t verified it on the phone itself, and
I can’t promise the same package mix on another ROM.

### Install

1. Install the ZIP from Magisk or a compatible recovery.
2. Press Volume Up for the default package set, or Volume Down to choose
   packages interactively.
3. Reboot.
4. Install and configure microG separately if your ROM’s setup requires it.

Keep a recovery route handy before changing system apps. This module is a
weekend project, not a substitute for a backup.

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
