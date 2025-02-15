import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jellyflix/providers/logger_provider.dart' show loggerProvider;
import 'package:jellyflix/services/jfx_logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:tentacle/tentacle.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:jellyflix/components/player_settings_dialog.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/providers/playback_helper_provider.dart';
import 'package:jellyflix/services/playback_helper_service.dart';

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
  late final logger;

  Timer? _timer;

  @override
  void initState() {
    logger = ref.read(loggerProvider);
    headers = ref.read(apiProvider).headers;

    streamUrl = widget.streamUrlAndPlaybackInfo.$1;
    playbackInfo = widget.streamUrlAndPlaybackInfo.$2;

    var playbackHelper = ref.read(playbackHelperProvider(playbackInfo));

    requestPermissions().then(
      (value) {
        player.open(Media(streamUrl,
            httpHeaders: headers,
            start: Duration(microseconds: widget.startTimeTicks ~/ 10)));

        player.stream.tracks.listen((event) async {
          List<AudioTrack> audioTracks = event.audio;
          List<SubtitleTrack> subtitleTracks = event.subtitle;
          Map<MediaStream, int?> audioStreams = playbackHelper.getAudioList();
          Map<MediaStream, int?> subtitleStreams =
              playbackHelper.getSubtitleList();

          if (audioStreams.length > 2) {
            var index = playbackHelper.getDefaultAudioIndex();
            // get value of the key, where key.index == index
            AudioTrack newAudioTrack = audioTracks[audioStreams.entries
                .firstWhere((element) => element.key.index == index,
                    orElse: () => audioStreams.entries.first)
                .value!];
            if (player.state.track.audio != newAudioTrack) {
              player.setAudioTrack(newAudioTrack);
            }
          }
          if (subtitleStreams.length > 2) {
            var index = playbackHelper.getDefaultSubtitleIndex();
            // get value of the key, where key.index == index
            MapEntry<MediaStream, int?> subtitleIndex = subtitleStreams.entries
                .firstWhere((element) => element.key.index == index,
                    orElse: () => subtitleStreams.entries.first);
            SubtitleTrack newSubtitleTrack;
            if (subtitleIndex.value == null) {
              logger.verbose(
                  "Player: External subtitle selected: ${subtitleIndex.key}");
              // external subtitle
              SubtitleTrack externalSubtitle = await ref
                  .read(apiProvider)
                  .getExternalSubtitle(
                      deliveryUrl: subtitleIndex.key.deliveryUrl!);
              newSubtitleTrack = externalSubtitle;
            } else {
              logger.verbose(
                  "Player: Internal subtitle selected: ${subtitleIndex.key}");
              newSubtitleTrack = subtitleTracks[subtitleIndex.value!];
            }
            if (player.state.track.subtitle != newSubtitleTrack) {
              player.setSubtitleTrack(newSubtitleTrack);
            }
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
          //TODO
          // await ref.read(apiProvider).reportPlaybackProgress(
          //       player.state.position.inMilliseconds * 10000,
          //       audioStreamIndex: player.state.track.audio.id == "auto"
          //           ? playbackHelper.getDefaultAudioIndex()
          //           : playbackHelper
          //               .getAudioList()
          //               .entries
          //               .firstWhere((element) =>
          //                   element.value ==
          //                   int.parse(player.state.track.audio.id))
          //               .key
          //               .index!,
          //       subtitleStreamIndex: player.state.track.subtitle.id == "auto"
          //           ? playbackHelper.getDefaultSubtitleIndex()
          //           : player.state.track.subtitle.id == "no"
          //               ? -1
          //               : playbackHelper
          //                   .getSubtitleList()
          //                   .entries
          //                   .firstWhere((element) =>
          //                       element.value ==
          //                       int.parse(player.state.track.subtitle.id))
          //                   .key
          //                   .index!,
          //     );
        });

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

  Future updateStream(
      audioStreamIndex, subtitleStreamIndex, maxStreamingBitrate) async {
    logger.verbose(
        "Updating stream with audioStreamIndex: $audioStreamIndex, subtitleStreamIndex: $subtitleStreamIndex, maxStreamingBitrate: $maxStreamingBitrate");
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
                seekBarThumbSize: 15,
                seekBarHeight: 4,
                seekBarMargin:
                    const EdgeInsets.only(bottom: 25, left: 10, right: 10),
                bottomButtonBarMargin:
                    const EdgeInsets.only(bottom: 40, left: 10, right: 10),
                seekOnDoubleTap: true,
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
                seekBarThumbSize: 15,
                seekBarHeight: 4,
                seekBarMargin:
                    const EdgeInsets.only(bottom: 25, left: 10, right: 10),
                bottomButtonBarMargin:
                    const EdgeInsets.only(bottom: 40, left: 10, right: 10),
                seekOnDoubleTap: true,
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
                    playAndPauseOnTap: true,
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
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialPositionIndicator(),
      ),
      if (!playbackHelper.subtitleListIsEmpty())
        MaterialDesktopCustomButton(
          onPressed: () async {
            subtitleEnabled.value = !subtitleEnabled.value;
            int trackNumber;
            if (subtitleEnabled.value) {
              if (subtitleTrack.value == -1) {
                subtitleTrack.value =
                    playbackHelper.getSubtitleList().keys.first.index!;
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
            var subtitleList = playbackHelper.getSubtitleList();
            var audioList = playbackHelper.getAudioList();

            showDialog(
              context: context,
              builder: (context) =>
                  PlayerSettingsDialog<MediaStream, MediaStream>(
                playbackHelper: playbackHelper,
                audioTrack: audioList.keys.firstWhere(
                    (element) => element.index! == audioTrack.value),
                subtitleTrack: subtitleList.entries
                    .firstWhere(
                        (element) => element.key.index! == subtitleTrack.value)
                    .key,
                isSubtitleEnabled: subtitleEnabled.value,
                maxStreamingBitrate: maxStreamingBitrate.value,
                audioEntries: audioList.entries
                    .map((e) => DropdownMenuEntry(
                        value: e.key,
                        label: e.key.index == 0
                            ? AppLocalizations.of(context)!.none
                            : e.key.displayTitle ?? "Unknown"))
                    .toList(),
                subtitleEntries: subtitleList.entries
                    .map((e) => DropdownMenuEntry(
                        value: e.key,
                        label: e.key.index == -1
                            ? AppLocalizations.of(context)!.none
                            : e.key.displayTitle ?? "Unknown"))
                    .toList(),
                onAudioSelected: (selectedMediaStream) async {
                  if (selectedMediaStream == null) {
                    return;
                  }
                  audioTrack.value = selectedMediaStream.index!;

                  int audioTrackIndex = audioList.entries
                          .firstWhere((element) =>
                              element.key.index == selectedMediaStream.index!)
                          .value ??
                      0; // default to 0 = auto
                  await player.setAudioTrack(audio[audioTrackIndex]);
                },
                onSubtitleSelected: (selectedMediaStream) async {
                  if (selectedMediaStream == null) {
                    return;
                  }

                  int selectedStreamId = selectedMediaStream.index!;
                  if (selectedStreamId == -1) {
                    subtitleEnabled.value = false;
                    // no subtitle
                    await player.setSubtitleTrack(subtitles[1]);
                  } else {
                    subtitleEnabled.value = true;
                    subtitleTrack.value = selectedMediaStream.index!;
                    int? subtitleTrackIndex = subtitleList.entries
                        .firstWhere((element) =>
                            element.key.index == selectedMediaStream.index!)
                        .value;
                    if (subtitleTrackIndex == null) {
                      logger.verbose(
                          "Player: External subtitle selected: $selectedMediaStream");
                      SubtitleTrack externalSubtitle = await ref
                          .read(apiProvider)
                          .getExternalSubtitle(
                              deliveryUrl: selectedMediaStream.deliveryUrl!);

                      await player.setSubtitleTrack(externalSubtitle);
                    } else {
                      logger.verbose(
                          "Player: Internal subtitle selected: $selectedMediaStream");
                      await player
                          .setSubtitleTrack(subtitles[subtitleTrackIndex]);
                    }
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
          } else {
            var subtitleEntries = [
              DropdownMenuEntry(
                  value: -1, label: AppLocalizations.of(context)!.none)
            ];
            subtitleEntries.addAll(playbackHelper.getSubtitleList().keys.map(
                (e) => DropdownMenuEntry(
                    value: e.index!, label: e.displayTitle ?? "Unknown")));
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
                    .keys
                    .map((e) => DropdownMenuEntry(
                        value: e.index, label: e.displayTitle ?? "Unknown"))
                    .toList(),
                subtitleEntries: subtitleEntries,
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
