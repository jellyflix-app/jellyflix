import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

class PlayerSreen extends StatefulWidget {
  const PlayerSreen({super.key, required this.url, required this.headers});
  final String url;
  final Map<String, String> headers;

  @override
  State<PlayerSreen> createState() => _PlayerSreenState();
}

class _PlayerSreenState extends State<PlayerSreen> {
  final player = Player();
  late final controller = VideoController(player);
  final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  @override
  void initState() {
    super.initState();
    requestPermissions().then(
      (value) {
        player.open(Media(widget.url, httpHeaders: widget.headers));
        player.stream.error.listen((error) => debugPrint(error));
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          key.currentState?.enterFullscreen();
        });
      },
    );
  }

  Future requestPermissions() async {
    if (UniversalPlatform.isAndroid) {
      // Video permissions.
      if (await Permission.videos.isDenied ||
          await Permission.videos.isPermanentlyDenied) {
        final state = await Permission.videos.request();
        if (!state.isGranted) {
          await SystemNavigator.pop();
        }
      }
      // Audio permissions.
      if (await Permission.audio.isDenied ||
          await Permission.audio.isPermanentlyDenied) {
        final state = await Permission.audio.request();
        if (!state.isGranted) {
          await SystemNavigator.pop();
        }
      }
    } else {
      if (await Permission.storage.isDenied ||
          await Permission.storage.isPermanentlyDenied) {
        final state = await Permission.storage.request();
        if (!state.isGranted) {
          await SystemNavigator.pop();
        }
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width * 9.0 / 16.0,
          // Use [Video] widget to display video output.
          child: MaterialDesktopVideoControlsTheme(
              normal: MaterialDesktopVideoControlsThemeData(
                  topButtonBar: [
                    BackButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  seekBarColor: Theme.of(context).colorScheme.secondary,
                  seekBarPositionColor: Theme.of(context).colorScheme.primary),
              fullscreen: MaterialDesktopVideoControlsThemeData(
                  topButtonBar: [
                    BackButton(
                      onPressed: () async {
                        await defaultExitNativeFullscreen();

                        if (context.mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                    ),
                  ],
                  seekBarColor: Theme.of(context).colorScheme.secondary,
                  seekBarPositionColor: Theme.of(context).colorScheme.primary),
              child: Video(
                key: key,
                controller: controller,
                onEnterFullscreen: () async {
                  await defaultEnterNativeFullscreen();
                },
                onExitFullscreen: () async {
                  await defaultExitNativeFullscreen();
                  if (!UniversalPlatform.isDesktop && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              )),
        ),
      ),
    );
  }
}
