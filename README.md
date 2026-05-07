# Absorb

[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/BarnabasApps)

A modern audiobookshelf client with a card-based player experience.

## Screenshots

<p align="center">
  <img src="screenshots/absorbing.png" width="200">
  &nbsp;
  <img src="screenshots/library.png" width="200">
  &nbsp;
  <img src="screenshots/details.png" width="200">
</p>
<p align="center">
  <img src="screenshots/fullScreen.png" width="200">
  &nbsp;
  <img src="screenshots/stats.png" width="200">
</p>

## Features

- **Card-based player** — full-screen "Absorbing" cards replace the traditional player screen
- **Audiobookshelf integration** — connects to your self-hosted audiobookshelf server
- **Offline playback** — download books for listening without a connection
- **Podcast support** — chaptered podcasts with rich HTML descriptions
- **Backup & restore** — export all settings to a `.absorb` file and import on any device, with optional account credentials for seamless device migration
- **Multi-account** — sign into multiple servers and switch between them
- **Sleep timer** with visual fill bar countdown, auto-sleep scheduling, and shake-to-reset
- **Playback speed** control with fine-grained slider and per-book speed memory
- **Auto-rewind** — configurable rewind after pausing based on how long you were away
- **Equalizer** — built-in audio EQ with bands and presets
- **Bookmarks** — save and jump to moments in any book
- **Chapter navigation** with dual progress bars (book + chapter)
- **Search & filtering** — full-text search, filter by progress/genre/series, multiple sort modes
- **Audible ratings** — see star ratings from Audible on your books
- **Auto-play next** — automatically continue to the next book in a series or next podcast episode
- **Android Auto** — browse and listen from your car
- **Chromecast** — cast playback to Google Cast devices (Android only)
- **Custom headers** — add custom HTTP headers for reverse proxy setups
- **OIDC/SSO login** — OpenID Connect support alongside standard auth
- **Server admin** — manage users, backups, and podcasts from the app
- **Listening stats** — track your listening history

## Install

[![Get it on GitHub](https://img.shields.io/badge/Get_it_on-GitHub-blue?style=for-the-badge&logo=github)](../../releases)
[![Get it on Obtainium](https://img.shields.io/badge/Get_it_on-Obtainium-teal?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTEyIDJMMiAyMmgyMEwxMiAyeiIgZmlsbD0id2hpdGUiLz48L3N2Zz4=)](https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/pounat/absorb)
[![Get it on Google Play](https://img.shields.io/badge/Google_Play-Open_Beta-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.barnabas.absorb)
[![Download on the App Store](https://img.shields.io/badge/App_Store-iOS-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://apps.apple.com/us/app/absorb-for-audiobookshelf/id6760673498)
[![Join TestFlight](https://img.shields.io/badge/TestFlight-iOS-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://testflight.apple.com/join/GgUbDbve)

### Release Tracks

**GitHub Pre-Releases (Alpha)** - Frequent updates with new features and bug fixes. In Obtainium you can toggle pre-releases on or off.

**GitHub Full Releases (Beta/Stable)** - Once a pre-release is solid, it gets promoted to a full release. These match what's pushed to Google Play and TestFlight.

### Google Play

Open testing is live - [join the open beta on Google Play](https://play.google.com/store/apps/details?id=com.barnabas.absorb). Open testing and production releases match GitHub full releases. Internal testing (alpha) matches GitHub pre-releases - join the [Discord](https://discord.gg/dW4Y4zCxRp) to request access to the internal track.

### App Store

Live on the [App Store](https://apps.apple.com/us/app/absorb-for-audiobookshelf/id6760673498). App Store releases match GitHub full releases. Some features are still Android-only or in progress, see iOS section below.

### iOS TestFlight

TestFlight tracks GitHub full releases the same as the App Store, useful if you want to test releases before they hit the store. [Join the TestFlight](https://testflight.apple.com/join/GgUbDbve).

### iOS Alpha (Sideload)

Alpha `.ipa` files are included in GitHub pre-releases alongside the Android APK. If you know how to sideload IPAs (via AltStore, Sideloadly, etc.), you can grab the latest alpha build from the [releases page](../../releases). Otherwise, stick with the TestFlight build for automatic updates and easier installation.

## Android Auto

Absorb supports Android Auto for browsing and listening from your car. If you are using the github version, you'll need to enable unknown sources in Android Auto:

> 1. Open **Android Auto** settings on your phone
> 2. Tap **Version** at the bottom repeatedly to enable Developer mode
> 3. Tap the three-dot menu (top right) and select **Developer settings**
> 4. Enable **Unknown sources**
>
> This is required because Absorb from Github is not distributed through Google Play's production track.

## iOS

### Working
If any of these aren't working as expected, please [open an issue](../../issues).

- [x] Library browsing, search, filtering, sorting
- [x] Streaming and offline playback
- [x] Downloads
- [x] Podcast support
- [x] Sleep timer, bookmarks, chapter navigation
- [x] Playback speed with per-book memory
- [x] Auto-rewind after pause
- [x] Bluetooth media controls (play/pause, skip, rewind)
- [x] Background audio
- [x] Lock screen / Control Center controls
- [x] Multi-account and server switching
- [x] Backup & restore
- [x] Dynamic theming
- [x] OIDC/SSO login
- [x] Custom headers
- [x] Listening stats
- [x] Auto-pause on Bluetooth disconnect
- [x]  Equalizer

### Not yet available on iOS
- [ ] Chromecast
- [ ] CarPlay (Android Auto equivalent)
- [ ] Home screen / Lock Screen widgets

## Requirements

- An [audiobookshelf](https://www.audiobookshelf.org/) server (self-hosted)
- Android 7.0+ / iOS 16+
