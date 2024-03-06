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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final player = Player(
      configuration: const PlayerConfiguration(
    libass: true,
    title: "Jellyflix",
  ));
  late final controller = VideoController(player);
  final GlobalKey<VideoState> key = GlobalKey<VideoState>();
  late PlaybackInfoResponse playbackInfo;
  late String streamUrl;
  late final Map<String, String> headers;

  Timer? _timer;

  @override
  void initState() {
    headers = ref.read(apiProvider).headers;

    streamUrl = widget.streamUrlAndPlaybackInfo.$1;
    playbackInfo = widget.streamUrlAndPlaybackInfo.$2;

    var playbackHelper = ref.read(playbackHelperProvider(playbackInfo));

    requestPermissions().then(
      (value) {
        player.open(Media(streamUrl,
            httpHeaders: headers,
            start: Duration(microseconds: widget.startTimeTicks ~/ 10)));

        player.stream.tracks.listen((event) {
          List<AudioTrack> audioTracks = event.audio;
          List<SubtitleTrack> subtitleTracks = event.subtitle;
          if (audioTracks.length > 2 &&
              playbackInfo.mediaSources!.first.transcodingUrl == null) {
            var index = playbackHelper.getDefaultAudioIndex();
            if (index == 0) {
              index = 1;
            }
            player.setAudioTrack(
                audioTracks[index + 1]); // index 0 should be auto
          }
          if (subtitleTracks.length > 2 &&
              playbackInfo.mediaSources!.first.transcodingUrl == null) {
            player.setSubtitleTrack(subtitleTracks[
                playbackHelper.getDefaultSubtitleIndex() == -1
                    ? 1
                    : playbackHelper.getDefaultSubtitleIndex() -
                        playbackHelper.getAudioList().length +
                        1]);
          }
        });

        ref.read(apiProvider).reportStartPlayback(widget.startTimeTicks);

        if (player.platform is NativePlayer) {
          (player.platform as dynamic).setProperty(
            'force-seekable',
            'yes',
          );
        }

        _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          await ref.read(apiProvider).reportPlaybackProgress(
              player.state.position.inMilliseconds * 10000,
              audioStreamIndex: player.state.track.audio.id == "auto"
                  ? playbackHelper.getDefaultAudioIndex()
                  : int.parse(player.state.track.audio.id),
              subtitleStreamIndex: player.state.track.subtitle.id == "auto"
                  ? playbackHelper.getDefaultSubtitleIndex()
                  : playbackHelper.getAudioList().length +
                      int.parse(player.state.track.subtitle.id));
        });

        player.stream.error.listen((error) => throw Exception(error));
        player.stream.completed.listen((completed) async {
          if (completed) {
            await ref.read(apiProvider).reportStopPlayback(
                player.state.position.inMilliseconds * 10000);
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
              maxStreamingBitrate: maxStreamingBitrate,
              audioStreamIndex: audioStreamIndex,
              subtitleStreamIndex: subtitleStreamIndex,
              startTimeTicks: startTimeTicks,
            );
    streamUrl = newStreamUrlAndPlaybackInfo.$1;
    playbackInfo = newStreamUrlAndPlaybackInfo.$2;
    player.open(Media(streamUrl,
        httpHeaders: headers,
        start: Duration(milliseconds: player.state.position.inMilliseconds)));
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
                seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
                seekBarThumbColor: Theme.of(context).colorScheme.primary,
              ),
              fullscreen: MaterialVideoControlsThemeData(
                topButtonBar: getTopButtonBarThemeData(context),
                bottomButtonBar: getBottomButtonBarThemeData(
                    playbackHelper,
                    subtitleEnabled,
                    subtitleTrack,
                    audioTrack,
                    maxStreamingBitrate,
                    context),
                seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
                seekBarThumbColor: Theme.of(context).colorScheme.primary,
              ),
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
                    seekBarPositionColor:
                        Theme.of(context).colorScheme.onPrimary,
                    seekBarThumbColor: Theme.of(context).colorScheme.primary,
                  ),
                  fullscreen: MaterialDesktopVideoControlsThemeData(
                    topButtonBar: getTopButtonBarThemeData(context),
                    bottomButtonBar: getBottomButtonBarThemeData(
                        playbackHelper,
                        subtitleEnabled,
                        subtitleTrack,
                        audioTrack,
                        maxStreamingBitrate,
                        context),
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
              if (subtitleTrack.value == -1) {
                subtitleTrack.value =
                    playbackHelper.getSubtitleList().first.index!;
              }
              trackNumber = subtitleTrack.value;
            } else {
              trackNumber = -1;
            }
            if (player.state.tracks.subtitle.length > 2) {
              var newTrack = trackNumber == -1
                  ? 1
                  : trackNumber - playbackHelper.getAudioList().length + 1;
              player.setSubtitleTrack(player.state.tracks.subtitle[newTrack]);
            } else {
              await updateStream(
                  audioTrack.value, trackNumber, maxStreamingBitrate.value);
            }
          },
          icon: ValueListenableBuilder(
            valueListenable: subtitleEnabled,
            builder: (context, value, child) {
              return Icon(
                subtitleEnabled.value
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_outlined,
                size: 25,
              );
            },
          ),
        ),
      const Spacer(),
      MaterialDesktopCustomButton(
        onPressed: () {
          var subtitles = player.state.tracks.subtitle;
          var audio = player.state.tracks.audio;
          if (playbackInfo.mediaSources!.first.transcodingUrl == null) {
            audio = audio.sublist(2);
            subtitles = subtitles.sublist(1);

            var subtitleList = playbackHelper.getSubtitleList();
            var audioList = playbackHelper.getAudioList();
            var audioTrackCount = audioList.length;

            var currentSubtitleIndex =
                subtitleTrack.value != -1 && subtitleEnabled.value
                    ? subtitleTrack.value - audioTrackCount
                    : 0;

            showDialog(
              context: context,
              builder: (context) =>
                  PlayerSettingsDialog<AudioTrack, SubtitleTrack>(
                playbackHelper: playbackHelper,
                audioTrack: audio[audioTrack.value - 1],
                subtitleTrack: subtitles[currentSubtitleIndex],
                isSubtitleEnabled: subtitleEnabled.value,
                maxStreamingBitrate: maxStreamingBitrate.value,
                audioEntries: audio
                    .map((e) => DropdownMenuEntry(
                        value: e,
                        label: audioList[audio.indexOf(e)].displayTitle!))
                    .toList(),
                subtitleEntries: subtitles
                    .map((e) => DropdownMenuEntry(
                        value: e,
                        label: subtitles.indexOf(e) == 0
                            ? AppLocalizations.of(context)!.none
                            : "${e.id}. ${subtitleList[subtitles.indexOf(e) - 1].displayTitle!}"))
                    .toList(),
                onAudioSelected: (value) async {
                  if (audio[audioTrack.value - 1] != value && value != null) {
                    audioTrack.value = int.parse(value.id);
                    player.setAudioTrack(value);
                  }
                },
                onSubtitleSelected: (value) async {
                  //if (subtitles[currentSubtitleIndex].id != value?.id &&
                  //    value != null) {
                  if (value!.id == "no") {
                    subtitleEnabled.value = false;
                    subtitleTrack.value = -1;
                  } else {
                    subtitleEnabled.value = true;
                    subtitleTrack.value = int.parse(value.id) + audioTrackCount;
                  }
                  player.setSubtitleTrack(value);
                  //}
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
          } else {
            showDialog(
              context: context,
              builder: (context) => PlayerSettingsDialog<int?, int?>(
                playbackHelper: playbackHelper,
                audioTrack: audioTrack.value,
                subtitleTrack: subtitleTrack.value,
                isSubtitleEnabled: subtitleEnabled.value,
                maxStreamingBitrate: maxStreamingBitrate.value,
                audioEntries: playbackHelper
                    .getAudioList()
                    .map((e) => DropdownMenuEntry(
                        value: e.index, label: e.language ?? "Unknown"))
                    .toList(),
                subtitleEntries: playbackHelper
                    .getSubtitleList()
                    .map((e) => DropdownMenuEntry(
                        value: e.index,
                        label:
                            e.language ?? AppLocalizations.of(context)!.none))
                    .toList(),
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
          }
        },
        icon: const Icon(
          Icons.settings_rounded,
          size: 20,
        ),
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
