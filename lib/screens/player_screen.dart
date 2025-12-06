import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/jfx_logger.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tentacle/tentacle.dart';
import 'package:universal_platform/universal_platform.dart';

class PlayerScreen extends StatefulHookConsumerWidget {
  const PlayerScreen(
      {super.key,
      required this.playerHelper,
      required this.startTimeTicks,
      required this.title});
  final PlayerHelper playerHelper;
  final int startTimeTicks;
  final String title;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerSreenState();
}

class _PlayerSreenState extends ConsumerState<PlayerScreen> {
  late final PlayerHelper playbackHelper;
  late final Player player;
  late final VideoController controller;
  final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  late String streamUrl;
  late final JfxLogger logger;

  @override
  void initState() {
    logger = ref.read(loggerProvider);

    playbackHelper = widget.playerHelper;

    player = playbackHelper.player;
    controller = playbackHelper.controller;

    requestPermissions().then(
      (value) async {
        await playbackHelper.initStream(widget.startTimeTicks);

        if (player.platform is NativePlayer) {
          (player.platform as dynamic).setProperty(
            'force-seekable',
            'yes',
          );
        }

        player.stream.error.listen((error) {
          if (mounted) {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("An error occured"),
                    content: Text(
                        "There was an error while loading the stream: $error"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                });
          }
          logger.error("An error occured while loading the stream: $error",
              error: error);
          throw Exception(error);
        });
        player.stream.completed.listen((completed) async {
          if (completed) {
            await playbackHelper.completedPlayback();
            await defaultExitNativeFullscreen();
            if (key.currentState?.isFullscreen() ?? false) {
              await key.currentState?.exitFullscreen();
            }
            if (mounted) {
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
    player.dispose();
    super.dispose();
  }

  void jumpToPosition(startTimeTicks) {
    bool isInitialSeek = true;

    player.stream.position.listen((event) {
      if (event.inMilliseconds > 0 &&
          event.inMilliseconds * 10000 < startTimeTicks - 10000 &&
          isInitialSeek) {
        player.seek(Duration(microseconds: startTimeTicks ~/ 10));
        logger.info("Seeking to ${startTimeTicks ~/ 10000000}s");
        isInitialSeek = false;
      }
    });
  }

  Future requestPermissions() async {
    if (UniversalPlatform.isAndroid) {
      if ((await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) {
        // Video permissions.
        if (await Permission.videos.isDenied ||
            await Permission.videos.isPermanentlyDenied) {
          final state = await Permission.videos.request();
          if (!state.isGranted && mounted) {
            goBackAndShowSnackBar(
                content: AppLocalizations.of(context)!.videoPermission);
          }
        }
        // Audio permissions.
        if (await Permission.audio.isDenied ||
            await Permission.audio.isPermanentlyDenied) {
          final state = await Permission.audio.request();
          if (!state.isGranted && mounted) {
            goBackAndShowSnackBar(
                content: AppLocalizations.of(context)!.audioPermission);
          }
        }
      } else {
        if (await Permission.storage.isDenied ||
            await Permission.storage.isPermanentlyDenied) {
          final state = await Permission.storage.request();
          if (!state.isGranted && mounted) {
            goBackAndShowSnackBar(
                content: AppLocalizations.of(context)!.storagePermission);
          }
        }
      }
    }
  }

  void goBackAndShowSnackBar({required String content}) {
    logger.warning(content);
    Navigator.of(context).pop();
    // show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.settings,
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitleEnabled =
        useValueNotifier<bool>(playbackHelper.getDefaultSubtitle().index != -1);
    final subtitleTrack =
        useState<MediaStream>(playbackHelper.getDefaultSubtitle());
    final audioTrack = useState<MediaStream>(playbackHelper.getDefaultAudio());
    final maxStreamingBitrate =
        useState<int>(playbackHelper.getDefaultBitrate());

    var materialVideoControlsThemeData = playbackHelper.videoControls(
      context,
      key,
      title: widget.title,
      subtitleEnabled: subtitleEnabled,
      subtitleTrack: subtitleTrack,
      audioTrack: audioTrack,
      maxStreamingBitrate: maxStreamingBitrate,
    );
    var materialDesktopVideoControlsThemeData =
        playbackHelper.desktopVideoControls(
      context,
      key,
      title: widget.title,
      subtitleEnabled: subtitleEnabled,
      subtitleTrack: subtitleTrack,
      audioTrack: audioTrack,
      maxStreamingBitrate: maxStreamingBitrate,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width * 9.0 / 16.0,
            // Use [Video] widget to display video output.
            child: MaterialVideoControlsTheme(
              normal: materialVideoControlsThemeData,
              fullscreen: materialVideoControlsThemeData,
              child: MaterialDesktopVideoControlsTheme(
                  normal: materialDesktopVideoControlsThemeData,
                  fullscreen: materialDesktopVideoControlsThemeData,
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
}
