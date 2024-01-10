import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/player_settings_dialog.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/playback_helper_provider.dart';
import 'package:jellyflix/services/playback_helper_service.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:openapi/openapi.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';

class PlayerScreen extends StatefulHookConsumerWidget {
  const PlayerScreen(
      {super.key,
      required this.streamUrlAndPlaybackInfo,
      required this.startTimeTicks});
  final (String, PlaybackInfoResponse) streamUrlAndPlaybackInfo;
  final int startTimeTicks;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerSreenState();
}

class _PlayerSreenState extends ConsumerState<PlayerScreen> {
  final player = Player();
  late final controller = VideoController(player);
  final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  late PlaybackInfoResponse playbackInfo;
  late String streamUrl;
  late final Map<String, String> headers;

  Timer? timer;

  @override
  void initState() {
    headers = ref.read(apiProvider).headers;

    streamUrl = widget.streamUrlAndPlaybackInfo.$1;
    playbackInfo = widget.streamUrlAndPlaybackInfo.$2;

    requestPermissions().then(
      (value) {
        player.open(Media(streamUrl, httpHeaders: headers));

        jumpToPosition(widget.startTimeTicks);
        ref.read(apiProvider).reportStartPlayback(widget.startTimeTicks);

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

        // report playback
        timer = Timer.periodic(
            const Duration(seconds: 5),
            (Timer t) => () async {
                  await ref.read(apiProvider).reportPlaybackProgress(
                      player.state.position.inMilliseconds * 10000);
                });
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
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
        isInitialSeek = false;
      }
    });
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

  Future updateStream(
      audioStreamIndex, subtitleStreamIndex, maxStreamingBitrate) async {
    var startTimeTicks = player.state.position.inMilliseconds * 10000;
    var newStreamUrlAndPlaybackInfo =
        await ref.read(apiProvider).getStreamUrlAndPlaybackInfo(
              itemId: playbackInfo.mediaSources!.first.id!,
              maxStreaminBitrate: maxStreamingBitrate,
              audioStreamIndex: audioStreamIndex,
              subtitleStreamIndex: subtitleStreamIndex,
              startTimeTicks: startTimeTicks,
            );
    streamUrl = newStreamUrlAndPlaybackInfo.$1;
    playbackInfo = newStreamUrlAndPlaybackInfo.$2;
    player.open(Media(streamUrl, httpHeaders: headers));
    jumpToPosition(startTimeTicks);
  }

  @override
  Widget build(BuildContext context) {
    final playbackHelper = ref.read(playbackHelperProvider(playbackInfo));
    final subtitleEnabled =
        useValueNotifier<bool>(playbackHelper.getDefaultSubtitleIndex() != -1);
    final subtitleTrack =
        useState<int>(playbackHelper.getDefaultSubtitleIndex());
    final audioTrack = useState<int>(playbackHelper.getDefaultAudioIndex());
    final maxStreamingBitrate =
        useState<int>(playbackHelper.getDefaultBitrate());

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
                  bottomButtonBar: getBottomButtonBarThemeData(
                      playbackHelper,
                      subtitleEnabled,
                      subtitleTrack,
                      audioTrack,
                      maxStreamingBitrate,
                      context),
                  seekBarColor: Theme.of(context).colorScheme.secondary,
                  seekBarPositionColor: Theme.of(context).colorScheme.primary),
              fullscreen: MaterialVideoControlsThemeData(
                  topButtonBar: getTopButtonBarThemeData(context),
                  bottomButtonBar: getBottomButtonBarThemeData(
                      playbackHelper,
                      subtitleEnabled,
                      subtitleTrack,
                      audioTrack,
                      maxStreamingBitrate,
                      context),
                  seekBarColor: Theme.of(context).colorScheme.secondary,
                  seekBarPositionColor: Theme.of(context).colorScheme.primary),
              child: MaterialDesktopVideoControlsTheme(
                  normal: MaterialDesktopVideoControlsThemeData(
                      topButtonBar: getTopButtonBarThemeData(context),
                      bottomButtonBar: getBottomButtonBarThemeData(
                          playbackHelper,
                          subtitleEnabled,
                          subtitleTrack,
                          audioTrack,
                          maxStreamingBitrate,
                          context),
                      seekBarColor: Theme.of(context).colorScheme.secondary,
                      seekBarPositionColor:
                          Theme.of(context).colorScheme.primary),
                  fullscreen: MaterialDesktopVideoControlsThemeData(
                      topButtonBar: getTopButtonBarThemeData(context),
                      bottomButtonBar: getBottomButtonBarThemeData(
                          playbackHelper,
                          subtitleEnabled,
                          subtitleTrack,
                          audioTrack,
                          maxStreamingBitrate,
                          context),
                      seekBarColor: Theme.of(context).colorScheme.secondary,
                      seekBarPositionColor:
                          Theme.of(context).colorScheme.primary),
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

  List<Widget> getBottomButtonBarThemeData(
      PlaybackHelperService playbackHelper,
      ValueNotifier<bool> subtitleEnabled,
      ValueNotifier<int> subtitleTrack,
      ValueNotifier<int> audioTrack,
      ValueNotifier<int> maxStreamingBitrate,
      BuildContext context) {
    return [
      const MaterialPlayOrPauseButton(),
      const MaterialDesktopVolumeButton(),
      const MaterialPositionIndicator(),
      if (!playbackHelper.subtitleListIsEmpty())
        MaterialDesktopCustomButton(
          onPressed: () async {
            subtitleEnabled.value = !subtitleEnabled.value;
            int trackNumber;
            if (subtitleEnabled.value) {
              trackNumber = subtitleTrack.value;
            } else {
              trackNumber = -1;
            }
            await updateStream(
                audioTrack.value, trackNumber, maxStreamingBitrate.value);
          },
          icon: ValueListenableBuilder(
            valueListenable: subtitleEnabled,
            builder: (context, value, child) {
              return Icon(
                subtitleEnabled.value
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_outlined,
              );
            },
          ),
        ),
      const Spacer(),
      MaterialDesktopCustomButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => PlayerSettingsDialog(
              playbackHelper: playbackHelper,
              audioTrack: audioTrack.value,
              subtitleTrack: subtitleTrack.value,
              isSubtitleEnabled: subtitleEnabled.value,
              maxStreamingBitrate: maxStreamingBitrate.value,
              onSubtitleSelected: (value) async {
                if (subtitleTrack.value != value) {
                  subtitleTrack.value = value ?? -1;
                  if (subtitleTrack.value == -1) {
                    subtitleEnabled.value = false;
                  } else {
                    subtitleEnabled.value = true;
                  }
                  await updateStream(audioTrack.value, subtitleTrack.value,
                      maxStreamingBitrate.value);
                }
              },
              onAudioSelected: (value) async {
                if (audioTrack.value != value) {
                  audioTrack.value = value ?? -1;
                  await updateStream(audioTrack.value, subtitleTrack.value,
                      maxStreamingBitrate.value);
                }
              },
              onBitrateSelected: (value) async {
                if (maxStreamingBitrate.value != value) {
                  maxStreamingBitrate.value = value!;
                  await updateStream(audioTrack.value, subtitleTrack.value,
                      maxStreamingBitrate.value);
                }
              },
            ),
          );
        },
        icon: const Icon(Icons.settings_rounded),
      ),
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
