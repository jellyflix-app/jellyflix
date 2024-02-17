import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

class OfflinePlayerScreen extends StatefulHookConsumerWidget {
  const OfflinePlayerScreen(
      {super.key, required this.streamPath, required this.startTimeTicks});
  final String streamPath;
  final int startTimeTicks;

  @override
  ConsumerState<OfflinePlayerScreen> createState() => _PlayerSreenState();
}

class _PlayerSreenState extends ConsumerState<OfflinePlayerScreen> {
  final player = Player(
      configuration: const PlayerConfiguration(
    libass: true,
    title: "Jellyflix",
  ));
  late final controller = VideoController(player);
  final GlobalKey<VideoState> key = GlobalKey<VideoState>();

  Timer? _timer;

  @override
  void initState() {
    requestPermissions().then(
      (value) {
        player.open(Media(widget.streamPath,
            start: Duration(microseconds: widget.startTimeTicks ~/ 10)));

        if (player.platform is NativePlayer) {
          (player.platform as dynamic).setProperty(
            'force-seekable',
            'yes',
          );
        }

        player.stream.error.listen((error) => throw Exception(error));
        player.stream.completed.listen((completed) async {
          if (completed) {
            await ref.read(apiProvider).reportStopPlayback(
                player.state.position.inMilliseconds * 10000);
            await defaultExitNativeFullscreen();
            if (key.currentState?.isFullscreen() ?? false) {
              await key.currentState?.exitFullscreen();
            }
            if (context.mounted) {
              context.pop();
            }
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          key.currentState?.enterFullscreen();
        });
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    player.dispose();
    super.dispose();
  }

  Future requestPermissions() async {
    if (UniversalPlatform.isAndroid) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            // Use [Video] widget to display video output.
            child: MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                topButtonBar: getTopButtonBarThemeData(context),
                bottomButtonBar: getBottomButtonBarThemeData(context),
                seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
                seekBarThumbColor: Theme.of(context).colorScheme.primary,
              ),
              fullscreen: MaterialVideoControlsThemeData(
                topButtonBar: getTopButtonBarThemeData(context),
                bottomButtonBar: getBottomButtonBarThemeData(context),
                seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
                seekBarThumbColor: Theme.of(context).colorScheme.primary,
              ),
              child: MaterialDesktopVideoControlsTheme(
                  normal: MaterialDesktopVideoControlsThemeData(
                    topButtonBar: getTopButtonBarThemeData(context),
                    bottomButtonBar: getBottomButtonBarThemeData(context),
                    seekBarPositionColor:
                        Theme.of(context).colorScheme.onPrimary,
                    seekBarThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  fullscreen: MaterialDesktopVideoControlsThemeData(
                    topButtonBar: getTopButtonBarThemeData(context),
                    bottomButtonBar: getBottomButtonBarThemeData(context),
                    seekBarPositionColor:
                        Theme.of(context).colorScheme.onPrimary,
                    seekBarThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Video(
                    key: key,
                    controller: controller,
                    onEnterFullscreen: () async {
                      await defaultEnterNativeFullscreen();
                    },
                    onExitFullscreen: () async {
                      await defaultExitNativeFullscreen();
                      if (!UniversalPlatform.isDesktop && context.mounted) {
                        context.pop();
                      }
                    },
                  )),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> getBottomButtonBarThemeData(BuildContext context) {
    return [
      const MaterialPlayOrPauseButton(),
      const MaterialDesktopVolumeButton(),
      const MaterialPositionIndicator(),
      const Spacer(),
      const MaterialFullscreenButton(),
    ];
  }

  List<Widget> getTopButtonBarThemeData(BuildContext context) {
    return [
      BackButton(
        onPressed: () async {
          await defaultExitNativeFullscreen();
          unawaited(ref
              .read(apiProvider)
              .reportStopPlayback(player.state.position.inMilliseconds * 10000)
              .then((value) {}));
          if (key.currentState?.isFullscreen() ?? false) {
            await key.currentState?.exitFullscreen();
          }
          if (context.mounted) {
            context.pop();
          }
        },
      ),
    ];
  }
}
