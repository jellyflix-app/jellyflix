{
  description = "Jellyflix - A Jellyfin client for multiple platforms";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        jellyflixSrc = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            let
              rel = pkgs.lib.removePrefix (toString ./. + "/") path;
            in
              pkgs.lib.cleanSourceFilter path type
              && !(pkgs.lib.hasPrefix "build/" rel)
              && !(pkgs.lib.hasPrefix ".dart_tool/" rel);
        };

        baseNativeBuildInputs = with pkgs; [
          flutter
          git
          curl
          unzip
          xz
        ];

        linuxNativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
          pkg-config
          cmake
          ninja
          xdg-user-dirs
        ]);

        linuxLibInputs = pkgs.lib.optionals pkgs.stdenv.isLinux (with pkgs; [
          gtk3
          glib
          pcre2
          util-linux
          libselinux
          libsepol
          libthai
          libdatrie
          libxkbcommon
          libepoxy
          at-spi2-core
          dbus
          libsecret
          sysprof
          alsa-lib
          libpulseaudio
          xorg.libXdmcp
          xorg.libX11
          libass
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-ugly
          gst_all_1.gst-libav
          mpv
        ]);

        mkFlutterDerivation = {
          pname,
          nativeBuildInputs ? [ ],
          buildInputs ? [ ],
          extraEnv ? "",
          flutterConfig ? "",
          buildCmd,
          installCmd,
          meta ? { },
        }:
          pkgs.stdenv.mkDerivation {
            inherit pname meta;
            version = "0.1.0";
            src = jellyflixSrc;

            nativeBuildInputs = baseNativeBuildInputs ++ nativeBuildInputs;
            buildInputs = buildInputs;

            buildPhase = ''
              export HOME=$TMPDIR
              ${extraEnv}
              flutter config --no-analytics
              ${flutterConfig}
              flutter pub get
              ${buildCmd}
            '';

            installPhase = installCmd;
          };

        # Build the Flutter web application
        jellyflixWeb = mkFlutterDerivation {
          pname = "jellyflix-web";
          nativeBuildInputs = with pkgs; [ jq ];
          flutterConfig = "flutter config --enable-web";
          buildCmd = "flutter build web --release";
          installCmd = ''
            mkdir -p $out/share/jellyflix
            cp -r build/web/* $out/share/jellyflix/
          '';
        };

        jellyflixLinux = mkFlutterDerivation {
          pname = "jellyflix-linux";
          nativeBuildInputs = linuxNativeBuildInputs;
          buildInputs = linuxLibInputs;
          flutterConfig = "flutter config --enable-linux-desktop";
          buildCmd = "flutter build linux --release";
          installCmd = ''
            mkdir -p $out/share/jellyflix
            cp -r build/linux/*/release/bundle/* $out/share/jellyflix/
          '';
          meta = {
            platforms = pkgs.lib.platforms.linux;
          };
        };

        jellyflixApk = mkFlutterDerivation {
          pname = "jellyflix-apk";
          nativeBuildInputs = with pkgs; [
            androidSdk
            jdk17
          ];
          extraEnv = ''
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk-bundle"
            export JAVA_HOME="${pkgs.jdk17}"
            export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
          '';
          buildCmd = "flutter build apk --release";
          installCmd = ''
            mkdir -p $out/share/jellyflix
            cp build/app/outputs/flutter-apk/app-release.apk $out/share/jellyflix/
          '';
          meta = {
            platforms = pkgs.lib.platforms.linux;
          };
        };

        jellyflixWindows = mkFlutterDerivation {
          pname = "jellyflix-windows";
          flutterConfig = "flutter config --enable-windows-desktop";
          buildCmd = "flutter build windows --release";
          installCmd = ''
            mkdir -p $out/share/jellyflix
            if [ -d build/windows/x64/runner/Release ]; then
              cp -r build/windows/x64/runner/Release/* $out/share/jellyflix/
            else
              cp -r build/windows/runner/Release/* $out/share/jellyflix/
            fi
          '';
          meta = {
            platforms = pkgs.lib.platforms.windows;
          };
        };

        # Common dependencies for all platforms
        commonBuildInputs = baseNativeBuildInputs
          ++ linuxNativeBuildInputs
          ++ linuxLibInputs;

        # Common shell setup
        commonShellHook = ''
          # Flutter setup
          export FLUTTER_ROOT="${pkgs.flutter}"
          export PATH="$FLUTTER_ROOT/bin:$PATH"

          ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Set up Flutter for Linux desktop development
            export PKG_CONFIG_PATH="${pkgs.gtk3}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:${pkgs.libepoxy}/lib/pkgconfig:${pkgs.libsecret}/lib/pkgconfig:${pkgs.sysprof.dev}/lib/pkgconfig:${pkgs.alsa-lib}/lib/pkgconfig:${pkgs.libass}/lib/pkgconfig:${pkgs.xorg.libXdmcp}/lib/pkgconfig:$PKG_CONFIG_PATH"

            # Set up XDG directories for path_provider plugin
            export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
            export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
            export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"

            # Initialize XDG user directories if not exists
            if [ ! -f "$HOME/.config/user-dirs.dirs" ]; then
              ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update
            fi
          ''}

          # Disable Flutter analytics
          flutter config --no-analytics 2>/dev/null || true

          ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Enable Linux desktop
            flutter config --enable-linux-desktop 2>/dev/null || true
          ''}

          # Enable web
          flutter config --enable-web 2>/dev/null || true

          echo "Jellyflix dev environment ready."
        '';

        # Linux-specific LD_LIBRARY_PATH
        linuxLibraryPath = pkgs.lib.optionalString pkgs.stdenv.isLinux (
          pkgs.lib.makeLibraryPath linuxLibInputs
        );

        # Android SDK configuration (only for full environment)
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "11.0";
          toolsVersion = "26.1.1";
          platformToolsVersion = "35.0.1";
          buildToolsVersions = [ "34.0.0" "33.0.2" ];
          includeEmulator = true;
          emulatorVersion = "34.2.16";
          platformVersions = [ "34" "33" "31" ];
          includeSources = false;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          abiVersions = [ "x86_64" "arm64-v8a" ];
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          ndkVersions = [ "26.3.11579264" ];
          useGoogleAPIs = false;
          useGoogleTVAddOns = false;
          includeExtras = [
            "extras;google;gcm"
          ];
        };

        androidSdk = androidComposition.androidsdk;

      in
      {
        packages = {
          default = jellyflixWeb;
          web = jellyflixWeb;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          apk = jellyflixApk;
          linux = jellyflixLinux;
        }
        // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isWindows {
          windows = jellyflixWindows;
        };

        # Default: Minimal environment for Linux development + web builds
        devShells.default = pkgs.mkShell {
          buildInputs = commonBuildInputs;

          shellHook = commonShellHook + ''
            echo "Shell: default (Linux + Web)."
          '';

          LD_LIBRARY_PATH = linuxLibraryPath;
        };

        # Web environment with bundled Chromium
        devShells.web = pkgs.mkShell {
          buildInputs = commonBuildInputs ++ (with pkgs; [
            chromium
          ]);

          shellHook = commonShellHook + ''
            # Chrome for web development
            export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

            echo "Shell: web (Linux + Web + Chromium)."
          '';

          LD_LIBRARY_PATH = linuxLibraryPath;
        };

        # Full environment with Android SDK
        devShells.full = pkgs.mkShell {
          buildInputs = commonBuildInputs ++ (with pkgs; [
            # Android development
            androidSdk
            jdk17
          ]);

          shellHook = commonShellHook + ''
            # Android SDK setup
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk-bundle"

            # Add Android tools to PATH
            export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

            # Java setup
            export JAVA_HOME="${pkgs.jdk17}"

            echo "Shell: full (Linux + Web + Android)."
          '';

          LD_LIBRARY_PATH = linuxLibraryPath;
        };

        # Optional: Add a formatter
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
