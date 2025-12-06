import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:jellyflix/components/player_settings_dialog.dart'
    show PlayerSettingsDialog;
import 'package:jellyflix/models/bitrates.dart';
import 'package:jellyflix/services/jfx_logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:tentacle/tentacle.dart';
import 'package:universal_platform/universal_platform.dart';

class PlayerHelper {
  late final JfxLogger logger;
  Map<int, String> bitrateMap = BitRates().map;

  PlaybackInfoResponse playbackInfo;
  late List<MediaStream> audioStreams;
  late List<MediaStream> subtitles;
  late Map<MediaStream, int?> mappedSubtitles;
  late Map<MediaStream, int?> mappedAudioStreams;

  late MediaStream audioStream;
  late MediaStream subtitle;
  late bool isSubtitleEnabled;
  late bool isTranscoding;
  bool showBitrate = true;

  final Player player = Player(
      configuration: const PlayerConfiguration(
    libass: true,
    libassAndroidFont: "assets/fonts/droid-sans.ttf",
    libassAndroidFontName: "Droid Sans Fallback",
    title: "Jellyflix",
  ));
  late final VideoController controller;

  PlayerHelper(
      {required this.playbackInfo, required this.logger, String? mpvConfig}) {
    initAudioList();
    initSubtitleList();
    audioStream = getDefaultAudio();
    subtitle = getDefaultSubtitle();
    isSubtitleEnabled = subtitle.index != -1;
    isTranscoding = playbackInfo.mediaSources![0].transcodingUrl != null;
    controller = VideoController(player);

    // Apply custom MPV config if provided
    if (mpvConfig != null && mpvConfig.isNotEmpty) {
      _applyMpvConfig(mpvConfig);
    }
  }

  void _applyMpvConfig(String config) {
    if (player.platform is NativePlayer) {
      final lines = config.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }
        final parts = trimmed.split('=');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          try {
            (player.platform as dynamic).setProperty(key, value);
          } catch (e) {
            logger.warning(
                "Failed to set MPV property '$key' with value '$value': $e");
            // Silently ignore invalid properties
          }
        }
      }
    }
  }

  Map<int, String> getBitrateMap() {
    // add orignal bitrate at the beginning
    bitrateMap[playbackInfo.mediaSources![0].bitrate ?? 0] =
        "Original ${playbackInfo.mediaSources![0].bitrate! ~/ 1000000} Mb/s";
    // add original bitrate at the beginning and sort the rest descending
    bitrateMap = Map.fromEntries(
      bitrateMap.entries.toList()..sort((e1, e2) => e2.key.compareTo(e1.key)),
    );
    // remove bitrates that are higher than the original
    bitrateMap.removeWhere(
        (key, value) => key > playbackInfo.mediaSources![0].bitrate!);

    return bitrateMap;
  }

  int getDefaultBitrate() {
    return playbackInfo.mediaSources![0].bitrate ?? 0;
  }

  void initSubtitleList() {
    MediaStream noneMediaStream = MediaStream(
      (b) {
        b.displayTitle = "None";
        b.index = -1;
        b.isExternal = false;
      },
    );
    // values are the index of the subtitle stream, if they are embedded
    subtitles = [
      noneMediaStream,
      ...playbackInfo.mediaSources![0].mediaStreams!
          .where((element) => element.type == MediaStreamType.subtitle)
          .toList()
    ];
    int index = 1;
    // map the subtitle streams to the index
    Map<MediaStream, int?> subtitleMap = {};
    for (var stream in subtitles) {
      if (stream.isExternal!) {
        subtitleMap.addAll({stream: null});
      } else {
        subtitleMap.addAll({stream: index});
        index++;
      }
    }
    mappedSubtitles = subtitleMap;
  }

  void initAudioList() {
    // values are the index of the embedded audio stream
    audioStreams = playbackInfo.mediaSources![0].mediaStreams!
        .where((element) => element.type == MediaStreamType.audio)
        .toList();
    int index = 2;
    // map the audio streams to the index
    Map<MediaStream, int?> audioMap = {};
    for (var stream in audioStreams) {
      audioMap.addAll({stream: index});
      index++;
    }

    mappedAudioStreams = audioMap;
  }

  MediaStream getDefaultAudio() {
    int index = playbackInfo.mediaSources![0].defaultAudioStreamIndex ?? -1;
    return audioStreams.firstWhere((element) => element.index == index);
  }

  MediaStream getDefaultSubtitle() {
    int index = playbackInfo.mediaSources![0].defaultSubtitleStreamIndex ?? -1;
    return subtitles.firstWhere((element) => element.index == index);
  }

  MaterialVideoControlsThemeData videoControls(
    BuildContext context,
    GlobalKey<VideoState> key, {
    required String title,
    required ValueNotifier<bool> subtitleEnabled,
    //TODO make required
    ValueNotifier<MediaStream>? subtitleTrack,
    ValueNotifier<MediaStream>? audioTrack,
    ValueNotifier<int>? maxStreamingBitrate,
  }) {
    return MaterialVideoControlsThemeData(
      topButtonBar: getTopButtonBarThemeData(context, key, title: title),
      bottomButtonBar: getBottomButtonBarThemeData(subtitleEnabled,
          subtitleTrack, audioTrack, maxStreamingBitrate, context),
      seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
      seekBarThumbColor: Theme.of(context).colorScheme.primary,
      seekBarThumbSize: 15,
      seekBarHeight: 4,
      seekBarMargin: const EdgeInsets.only(bottom: 55),
      padding: const EdgeInsets.only(left: 50, right: 50),
      seekOnDoubleTap: true,
      volumeGesture: true,
      brightnessGesture: true,
    );
  }

  MaterialDesktopVideoControlsThemeData desktopVideoControls(
    BuildContext context,
    GlobalKey<VideoState> key, {
    required String title,
    required ValueNotifier<bool> subtitleEnabled,
    required ValueNotifier<MediaStream>? subtitleTrack,
    required ValueNotifier<MediaStream>? audioTrack,
    required ValueNotifier<int>? maxStreamingBitrate,
  }) {
    return MaterialDesktopVideoControlsThemeData(
      topButtonBar: getTopButtonBarThemeData(context, key, title: title),
      bottomButtonBar: getBottomButtonBarThemeData(subtitleEnabled,
          subtitleTrack, audioTrack, maxStreamingBitrate, context),
      seekBarPositionColor: Theme.of(context).colorScheme.onPrimary,
      seekBarThumbColor: Theme.of(context).colorScheme.primary,
      playAndPauseOnTap: true,
    );
  }

  List<Widget> getTopButtonBarThemeData(
      BuildContext context, GlobalKey<VideoState> key,
      {required String title}) {
    return [
      BackButton(
        onPressed: () async {
          try {
            await backButtonPressed().timeout(const Duration(seconds: 2));
          } catch (e) {
            logger.error("Player: Couldn't report playback finished");
          }
          if (UniversalPlatform.isDesktop &&
              (key.currentState?.isFullscreen() ?? false)) {
            await key.currentState?.exitFullscreen();
          }
          if (context.mounted) {
            context.pop();
          }
        },
      ),
      const SizedBox(width: 10),
      Text(title),
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

  Future<void> setSubtitle(MediaStream mediaStream) {
    throw UnimplementedError();
  }

  Future<void> disableSubtitle() {
    throw UnimplementedError();
  }

  Future<void> enableSubtitle() {
    throw UnimplementedError();
  }

  Future<void> setAudio(MediaStream mediaStream) {
    throw UnimplementedError();
  }

  Future<void> setBitrate(int maxStreamingBitrate) {
    throw UnimplementedError();
  }

  List<Widget> getBottomButtonBarThemeData(
      ValueNotifier<bool> subtitleEnabled,
      ValueNotifier<MediaStream>? subtitleTrack,
      ValueNotifier<MediaStream>? audioTrack,
      ValueNotifier<int>? maxStreamingBitrate,
      BuildContext context) {
    return [
      const MaterialPlayOrPauseButton(),
      const MaterialDesktopVolumeButton(),
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialPositionIndicator(),
      ),
      if (subtitles.length > 1)
        MaterialDesktopCustomButton(
          onPressed: () async {
            subtitleEnabled.value = !subtitleEnabled.value;
            if (subtitleEnabled.value) {
              await enableSubtitle();
            } else {
              await disableSubtitle();
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
      if (showBitrate || subtitles.length > 1 || audioStreams.length > 1)
        MaterialDesktopCustomButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => PlayerSettingsDialog(
                playbackHelper: this,
                showBitrate: showBitrate,
                audioTrack: audioTrack!.value,
                subtitleTrack: subtitleTrack!.value,
                isSubtitleEnabled: subtitleEnabled.value,
                maxStreamingBitrate: maxStreamingBitrate!.value,
                onSubtitleSelected: (value) async {
                  if (value != null) {
                    subtitleEnabled.value = value.index == -1 ? false : true;
                    subtitleTrack.value = value;
                    //logger.verbose("Setting subtitle: ${value.displayTitle}");
                    await setSubtitle(value);
                  }
                },
                onAudioSelected: (value) async {
                  if (audioTrack.value != value) {
                    audioTrack.value = value!;
                    await setAudio(value);
                  }
                },
                onBitrateSelected: (value) async {
                  if (maxStreamingBitrate.value != value) {
                    maxStreamingBitrate.value = value!;
                    await setBitrate(value);
                    // opening a new stream will reset the subtitle track
                    if (subtitleEnabled.value) {
                      await enableSubtitle();
                    }
                  }
                },
              ),
            );
          },
          icon: const Icon(
            Icons.settings_rounded,
            size: 20,
          ),
        ),
      const MaterialFullscreenButton(),
    ];
  }

  Future<void> backButtonPressed() async {
    throw UnimplementedError();
  }

  Future<void> initStream(int startTimeTicks) {
    throw UnimplementedError();
  }

  Future<void> completedPlayback() async {
    throw UnimplementedError();
  }
}
