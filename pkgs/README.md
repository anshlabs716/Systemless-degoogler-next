# Bundled APK inventory

Regular APKs live in `pkgs/` and are installed with `pm install` during
module install (`customize.sh`), once, before any Google app is removed.
The privileged apps live in `system/priv-app` and are mounted by the root
manager at boot; their runtime permissions are granted by the boot service.
The install is fully unattended: there are no volume-key prompts.
Futo Keyboard is pre-installed before Gboard is masked. PixelBoard requires
GMS or microG. An APK whose package is already installed is skipped.

## Regular apps (installed from `pkgs/`)

| App | Package ID | APK path | Version |
|---|---|---|---|
| F-Droid Basic | `org.fdroid.basic` | `pkgs/01_fdroid.apk` | 2.0.2 |
| Neo Store | `com.machiav3lli.fdroid` | `pkgs/02_neostore.apk` | 1.3.2 |
| Aurora Store | `com.aurora.store` | `pkgs/03_aurora.apk` | 4.8.4 |
| Proton VPN | `ch.protonvpn.android.reproducible` | `pkgs/04_protonvpn.apk` | 5.20.98.0 |
| Proton Pass (F-Droid) | `proton.android.pass.fdroid` | `pkgs/05_protonpass.apk` | 1.41.4 |
| Ente Photos | `io.ente.photos.fdroid` | `pkgs/06_ente.apk` | 1.3.66 |
| Simple Notes Sync | `dev.dettmer.simplenotes` | `pkgs/07_simplenotes.apk` | 2.20.1 |
| CalcYou | `net.youapps.calcyou` | `pkgs/08_calcyou.apk` | 5.3 |
| Breezy Weather | `org.breezyweather` | `pkgs/09_breezy.apk` | 6.2.2_freenet |
| Brave | `com.brave.browser` | `pkgs/10_brave.apk` | 1.78.97 |
| Koda | `com.ivor.ivormusic` | `pkgs/11_koda.apk` | 5.2 |
| Auxio | `org.oxycblt.auxio` | `pkgs/12_auxio.apk` | 4.1.5 |
| Vela Maps | `app.vela` | `pkgs/13_vela.apk` | 0.5.2621 |
| Proton Drive | `me.proton.android.drive` | `pkgs/14_protondrive.apk` | 3.2.0 |
| Dicio | `org.stypox.dicio` | `pkgs/15_dicio.apk` | 4.2 |
| RHVoice | `com.github.olga_yakovleva.rhvoice.android` | `pkgs/16_rhvoice.apk` | 1.18.4 |
| Thunderbird | `net.thunderbird.android` | `pkgs/17_thunderbird.apk` | 24.0 |
| Bada | `dev.bluehouse.bada` | `pkgs/26_bada.apk` | 20261007.01 |
| NetGuard | `dev.ukanth.ufirewall` | `pkgs/27_netguard.apk` | 5.0.0-BETA_1 |
| Compass | `com.bobek.compass` | `pkgs/28_compass.apk` | 2.2.0 |
| Futo Keyboard | `org.futo.inputmethod.latin` | `pkgs/29_futo.apk` | 0.1.30 |
| PixelBoard | `com.akshaykadam.pixelboard` | `pkgs/30_pixelboard.apk` | 18.5.3.993608717-release-arm64-v8a |
| MILES | `com.anshlabs.miles` | `pkgs/31_miles.apk` | 1.1.6 |

## Privileged system apps

| App | Package ID | APK path | Version |
|---|---|---|---|
| DeskClock | `com.android.deskclock` | `system/priv-app/DeskClock/DeskClock.apk` | 16 |
| WebView | `com.android.webview` | `system/priv-app/WebView/WebView.apk` | 153.0.8010.37 |
| Etar Calendar | `org.lineageos.etar` | `system/priv-app/Etar/Etar.apk` | 14 |
| Recorder | `org.lineageos.recorder` | `system/priv-app/Recorder/Recorder.apk` | 16 |
| Fossify Phone | `org.fossify.phone` | `system/priv-app/FossifyPhone/FossifyPhone.apk` | 1.11.1 |
| Fossify Messages | `org.fossify.messages` | `system/priv-app/FossifyMessages/FossifyMessages.apk` | 1.10.2 |
| Fossify Contacts | `org.fossify.contacts` | `system/priv-app/FossifyContacts/FossifyContacts.apk` | 1.6.0 |
| Fossify Files | `org.fossify.filemanager` | `system/priv-app/FossifyFiles/FossifyFiles.apk` | 1.6.3 |
