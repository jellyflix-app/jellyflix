⚠️ Please keep in mind, that Jellyflix development is in its early days. There are several (visual) bugs and many features missing. If you don't like the state of Jellyflix client right now, you can help improve it by contributing 😉.

---

# Jellyflix - Another Jellyfin client

Jellyflix is a cross platform Jellyfin Client for Desktop (Mac, Windows, Linux) and Mobile (iOS, Android). It aims to be a simple to use and reliable Jellyfin client for video content. It supports downloads (coming soon).

## Download
Coming soon™️ For now you have to build Jellyflix yourself. <br>
Supported platforms:
- iOS
- Android
- macOS
- Windows (untested)
- Linux (untested)
- Web (technically works, but won't have the same download support like the other platforms)

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
