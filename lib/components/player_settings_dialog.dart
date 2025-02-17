import 'package:flutter/material.dart';
import 'package:jellyflix/services/playback_helper_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tentacle/tentacle.dart';

class PlayerSettingsDialog extends StatelessWidget {
  final PlaybackHelperService playbackHelper;
  final MediaStream audioTrack;
  final MediaStream subtitleTrack;
  final int maxStreamingBitrate;
  final bool isSubtitleEnabled;
  final Function(MediaStream?) onSubtitleSelected;
  final Function(MediaStream?) onAudioSelected;
  final Function(int?) onBitrateSelected;

  const PlayerSettingsDialog({
    super.key,
    required this.playbackHelper,
    required this.audioTrack,
    required this.subtitleTrack,
    required this.maxStreamingBitrate,
    required this.onSubtitleSelected,
    required this.onAudioSelected,
    required this.onBitrateSelected,
    required this.isSubtitleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    var subtitle = playbackHelper.subtitles
        .firstWhere((e) => e.index == subtitleTrack.index);
    var audio = playbackHelper.audioStreams
        .firstWhere((e) => e.index == audioTrack.index);
    return SafeArea(
        child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 50.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocalizations.of(context)!.settings,
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Material(
                            child: DropdownMenu(
                                width: 250,
                                requestFocusOnTap: false,
                                label:
                                    Text(AppLocalizations.of(context)!.quality),
                                leadingIcon:
                                    const Icon(Icons.videocam_outlined),
                                initialSelection: maxStreamingBitrate,
                                dropdownMenuEntries: playbackHelper
                                    .getBitrateMap()
                                    .entries
                                    .toList()
                                    .map((e) {
                                  return DropdownMenuEntry(
                                      value: e.key, label: e.value);
                                }).toList(),
                                onSelected: onBitrateSelected),
                          ),
                          const SizedBox(height: 10),
                          Material(
                            child: DropdownMenu(
                              width: 250,
                              requestFocusOnTap: false,
                              label: Text(AppLocalizations.of(context)!.audio),
                              leadingIcon: const Icon(Icons.volume_up_rounded),
                              initialSelection: audio,
                              dropdownMenuEntries: playbackHelper.audioStreams
                                  .map((e) => DropdownMenuEntry(
                                      value: e,
                                      label: e.displayTitle ?? "Unknown"))
                                  .toList(),
                              onSelected: onAudioSelected,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (playbackHelper.subtitles.isNotEmpty)
                            Material(
                              child: DropdownMenu<MediaStream>(
                                  width: 250,
                                  label: Text(
                                      AppLocalizations.of(context)!.subtitles),
                                  requestFocusOnTap: false,
                                  leadingIcon:
                                      const Icon(Icons.videocam_outlined),
                                  initialSelection: subtitle,
                                  dropdownMenuEntries: playbackHelper.subtitles
                                      .map((e) => DropdownMenuEntry(
                                          value: e,
                                          label: e.displayTitle ?? "Unknown"))
                                      .toList(),
                                  onSelected: onSubtitleSelected),
                            ),
                        ]),
                  ),
                ),
              ),
            )));
  }
}
