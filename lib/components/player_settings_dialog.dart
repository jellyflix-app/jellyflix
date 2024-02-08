import 'package:flutter/material.dart';
import 'package:jellyflix/services/playback_helper_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlayerSettingsDialog<T1, T2> extends StatelessWidget {
  final PlaybackHelperService playbackHelper;
  final T1 audioTrack;
  final T2 subtitleTrack;
  final List<DropdownMenuEntry<T1>> audioEntries;
  final List<DropdownMenuEntry<T2>> subtitleEntries;
  final int maxStreamingBitrate;
  final bool isSubtitleEnabled;
  final Function(T2?) onSubtitleSelected;
  final Function(T1?) onAudioSelected;
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
    required this.audioEntries,
    required this.subtitleEntries,
  });

  @override
  Widget build(BuildContext context) {
    // List<DropdownMenuEntry<T2>> subtitleMenuEntries =
    //     subtitleList.map((e) {
    //   return DropdownMenuEntry(value: , label: e.displayTitle!);
    // }).toList();
    // // add "None" to the beginning
    // subtitleMenuEntries.insert(
    //     0,
    //     DropdownMenuEntry(
    //         value: -1, label: AppLocalizations.of(context)!.none));
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
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
                              leadingIcon: const Icon(Icons.videocam_outlined),
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
                          child: DropdownMenu<T1>(
                            width: 250,
                            requestFocusOnTap: false,
                            label: Text(AppLocalizations.of(context)!.audio),
                            leadingIcon: const Icon(Icons.volume_up_rounded),
                            initialSelection: audioTrack,
                            dropdownMenuEntries: audioEntries,
                            onSelected: onAudioSelected,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!playbackHelper.subtitleListIsEmpty())
                          Material(
                            child: DropdownMenu<T2>(
                                width: 250,
                                label: Text(
                                    AppLocalizations.of(context)!.subtitles),
                                requestFocusOnTap: false,
                                leadingIcon:
                                    const Icon(Icons.videocam_outlined),
                                initialSelection: subtitleTrack,
                                dropdownMenuEntries: subtitleEntries,
                                onSelected: onSubtitleSelected),
                          ),
                      ]),
                ),
              ),
            )));
  }
}
