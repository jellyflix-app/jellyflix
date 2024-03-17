# Jellyflix - Another Jellyfin client
[![](https://img.shields.io/badge/matrix-000000?style=for-the-badge&logo=Matrix&logoColor=white)](https://matrix.to/#/#jellyflix-space:matrix.org)

Jellyflix is a cross platform Jellyfin Client for Desktop (Mac, Windows, Linux) and Mobile (iOS, Android). It aims to be a simple to use and reliable Jellyfin client for video content. It supports transcoded downloads and much more. 

## Features
- Browse and watch your video content
- Cross-platform (iOS, Android, macOS, Windows, Linux, Web)
- Supports a wide variety of media formats
- Download (transcoded) media for offline usage
- Tonemapping support for HDR content
- Save items you want to watch in your watchlist
- Profiles for different users and servers
- Quick connect support

## Download
Jellyflix is available for all major platforms. You can download them from the following links or from the [releases](https://github.com/jellyflix-app/jellyflix/releases) page. On this page you can also find pre-release builds. 
### iOS
  [![](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/de/app/jellyflix/id6476043683) 
  
  Beta-Builds are available on Testflight. Join Testflight [here](https://testflight.apple.com/join/Nc1Jw9tc).

### Android
  [![](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/jellyflix-app/jellyflix/releases/latest/download/jellyflix.apk) 
  
  Google Play and F-Droid coming soon
### macOS

[![](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/de/app/jellyflix/id6476043683)

Note: There is a native .dmg file available, but there are login issues after notarization. As a workaround, you can use the iOS app on macOS. The iOS version looks and works the same as the macOS app.

### Windows
[![](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/jellyflix-app/jellyflix/releases/latest/download/jellyflix-windows.zip)

### Linux
[![](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/jellyflix-app/jellyflix/releases/latest/download/jellyflix-linux.zip)

The Linux version needs additional dependencies, see [below](#linux).

### Web
[![](https://img.shields.io/badge/Web-000000?style=for-the-badge&logo=web&logoColor=white)](https://jellyflix.kiejon.com)

The web version is only intended for demo usage and doesn't support all the features.

## Contribute
Contributions are much appreciated. You can help the development by:
- opening issues/bug reports
- suggest features or give feedback
- translating the app
- contributing with pull requests

## Build
Jellyflix is developed in Flutter a cross-platform framework. The programming language is Dart, which is quite easy to learn. <br>
To build the project you need Flutter [installed](https://docs.flutter.dev/get-started/install) and at least one supported device/emulator to run the project on. <br>
Then clone the repository and run the following commands.
```
cd jellyflix
flutter clean
flutter pub get
flutter run
```

## Linux
If you want to build Jellyflix for Linux you need some additional dependencies: `libmpv-dev, mpv, libsecret-1-dev, libjsoncpp-dev

## Privacy
Jellyflix doesn't collect data and doesn't send data to third parties.

## License
Jellyflix is licensed under [GPLv3](LICENSE).

The Jellyflix logo is licensed under [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) and is a remix of the original [Jellyfin icon](https://github.com/jellyfin/jellyfin-ux/blob/master/branding/SVG/icon-transparent.svg) by the [Jellyfin Project](https://jellyfin.org/) which is licensed under [CC-BY-SA 4.0](https://github.com/jellyfin/jellyfin-ux/blob/master/LICENSE)