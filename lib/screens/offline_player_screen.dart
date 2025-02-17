import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            // await ref.read(apiProvider).reportStopPlayback(
            //     player.state.position.inMilliseconds * 10000);
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
    _timer?.cancel();
    player.dispose();
    super.dispose();
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
                seekBarThumbSize: 15,
                seekBarHeight: 4,
                seekOnDoubleTap: true,
                seekBarMargin:
                    const EdgeInsets.only(bottom: 25, left: 10, right: 10),
                bottomButtonBarMargin:
                    const EdgeInsets.only(bottom: 40, left: 10, right: 10),
              ),
              fullscreen: MaterialVideoControlsThemeData(
                topButtonBar: getTopButtonBarThemeData(context),
                bottomButtonBar: getBottomButtonBarThemeData(context),
                seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
                seekBarThumbColor: Theme.of(context).colorScheme.primary,
                seekBarThumbSize: 15,
                seekBarHeight: 4,
                seekOnDoubleTap: true,
                seekBarMargin:
                    const EdgeInsets.only(bottom: 25, left: 10, right: 10),
                bottomButtonBarMargin:
                    const EdgeInsets.only(bottom: 40, left: 10, right: 10),
              ),
              child: MaterialDesktopVideoControlsTheme(
                  normal: MaterialDesktopVideoControlsThemeData(
                    topButtonBar: getTopButtonBarThemeData(context),
                    bottomButtonBar: getBottomButtonBarThemeData(context),
                    seekBarPositionColor:
                        Theme.of(context).colorScheme.onPrimary,
                    seekBarThumbColor: Theme.of(context).colorScheme.primary,
                    playAndPauseOnTap: true,
                  ),
                  fullscreen: MaterialDesktopVideoControlsThemeData(
                    topButtonBar: getTopButtonBarThemeData(context),
                    bottomButtonBar: getBottomButtonBarThemeData(context),
                    seekBarPositionColor:
                        Theme.of(context).colorScheme.onPrimary,
                    seekBarThumbColor: Theme.of(context).colorScheme.primary,
                    playAndPauseOnTap: true,
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
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialPositionIndicator(),
      ),
      const Spacer(),
      const MaterialFullscreenButton(),
    ];
  }

  List<Widget> getTopButtonBarThemeData(BuildContext context) {
    return [
      BackButton(
        onPressed: () async {
          await defaultExitNativeFullscreen();
          if (key.currentState?.isFullscreen() ?? false) {
            await key.currentState?.exitFullscreen();
          }
          if (context.mounted) {
            context.pop();
          }
        },
      ),
      const Spacer(),
      StreamBuilder(
        stream: player.stream.position,
        builder: (context, snapshot) {
          return Text(AppLocalizations.of(context)!.ends(
              intl.DateFormat("HH:mm").format(DateTime.now()
                  .add(Duration(
                      minutes: player.state.duration.inMinutes -
                          player.state.position.inMinutes))
                  .toLocal())));
        },
      )
    ];
  }
}
