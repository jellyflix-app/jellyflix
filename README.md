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

[![](https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.ambark.jellyflix&hl=en)

F-Droid coming soon

### macOS
[![](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://github.com/jellyflix-app/jellyflix/releases/latest/download/jellyflix.dmg)

There is a native macOS app available. You can download it from the link above. Or you can download the iOS version from the App Store and run it on your M series Mac.

[![](https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white)](https://apps.apple.com/de/app/jellyflix/id6476043683)

### Windows

[![](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/jellyflix-app/jellyflix/releases/latest/download/jellyflix-windows.zip)

### Linux

[![](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/jellyflix-app/jellyflix/releases/latest)
Download and extract the version that is most suitable for your system.

You also need to install the following dependencies to run Jellyflix:
```bash
sudo apt install libjsoncpp-dev libsecret-1-0 libmpv-dev mpv
```

If Jellyflix can't launch because it can't find libmpv or has key-ring issues. You can [the documentation below](#linux-1
You might be prompted to choose a password for the keyring. This is a system dialog and not a Jellyflix dialog. The password is used to store the Jellyfin credentials securely.

### Web

[![](https://img.shields.io/badge/Web-000000?style=for-the-badge&logo=web&logoColor=white)](https://jellyflix.kiejon.com)

The web version is only intended for demo usage and doesn't support all the features. E.g. playback is not supported.

## Contribute

Contributions are much appreciated. You can help the development by:

- opening issues/bug reports
- suggest features or give feedback
- translating the app
- contributing with pull requests

### Translation

We are using a Weblate Instance provided by [Codeberg](https://codeberg.org/) for translations. You can find the project [here](https://translate.codeberg.org/engage/jellyflix/). If you want to contribute to the translation, you can create an account on Weblate and start translating.

<a href="https://translate.codeberg.org/engage/jellyflix/">
<img src="https://translate.codeberg.org/widget/jellyflix/jellyflix/multi-auto.svg" alt="Übersetzungsstatus" />
</a>

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

If you want to build Jellyflix for Linux you need some additional dependencies:

```bash
# Flutter needs the following dependencies, if not already installed
sudo apt install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

# Jellyflix needs the following additonal dependencies
# Using apt:
sudo apt install libjsoncpp-dev libmpv-dev libsecret-1-dev mpv
# Using dnf:
sudo dnf install jsoncpp-devel libsecret libsecret-devel mpv mpv-libs mpv-devel
```

Apart from libsecret you also need a keyring service, for that you need either gnome-keyring (for Gnome users) or ksecretsservice (for KDE users) or other light provider like [secret-service](https://github.com/yousefvand/secret-service).

If your distro only provides libmpv, this workaround is necessary:

```bash
# Debian based:
sudo ln -s /usr/lib/x86_64-linux-gnu/libmpv.so.2 /usr/lib/x86_64-linux-gnu/libmpv.so.1
# Fedora based:
sudo ln -s /usr/lib64/libmpv.so /usr/lib64/libmpv.so.1
```

#### We would welcome the contribution of build instructions for Fedora. Unfortunately, as of now, there are no developers using Fedora-like systems.

## Privacy

Jellyflix doesn't collect data and doesn't send data to third parties.

## License

Jellyflix is licensed under [GPLv3](LICENSE).

The Jellyflix logo is licensed under [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) and is a remix of the original [Jellyfin icon](https://github.com/jellyfin/jellyfin-ux/blob/master/branding/SVG/icon-transparent.svg) by the [Jellyfin Project](https://jellyfin.org/) which is licensed under [CC-BY-SA 4.0](https://github.com/jellyfin/jellyfin-ux/blob/master/LICENSE)
