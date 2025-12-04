import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/logger_provider.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:tentacle/tentacle.dart';
import 'package:jellyflix/l10n/generated/app_localizations.dart';

class DownloadSettingsDialog extends HookConsumerWidget {
  final PlaybackInfoResponse downloadInfo;

  const DownloadSettingsDialog({super.key, required this.downloadInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.read(loggerProvider);
    final playerHelper =
        PlayerHelper(playbackInfo: downloadInfo, logger: logger);
    MediaStream selectedAudio = playerHelper.getDefaultAudio();
    MediaStream selectedSubtitle = playerHelper.getDefaultSubtitle();
    if (selectedSubtitle.deliveryMethod == SubtitleDeliveryMethod.embed) {
      selectedSubtitle = playerHelper.subtitles
          .firstWhere((element) => element.index == selectedSubtitle.index);
    }
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.setAudioAndSubtitleLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          if (playerHelper.audioStreams.length > 1 &&
              playerHelper.isTranscoding)
            DropdownMenu<MediaStream>(
              expandedInsets: EdgeInsets.zero,
              enableSearch: false,
              enableFilter: false,
              requestFocusOnTap: false,
              leadingIcon: const Icon(Icons.audiotrack),
              initialSelection: selectedAudio,
              label: Text(AppLocalizations.of(context)!.audio),
              dropdownMenuEntries: playerHelper.audioStreams
                  .map(
                    (e) => DropdownMenuEntry(
                      value: e,
                      labelWidget: Text(
                        e.displayTitle ?? AppLocalizations.of(context)!.none,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      label:
                          e.displayTitle ?? AppLocalizations.of(context)!.none,
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                if (value != null) {
                  selectedAudio = value;
                }
              },
            ),
          const SizedBox(height: 20),
          if (playerHelper.subtitles.length > 1)
            DropdownMenu<MediaStream>(
              expandedInsets: EdgeInsets.zero,
              enableSearch: false,
              enableFilter: false,
              requestFocusOnTap: false,
              leadingIcon: const Icon(Icons.subtitles_outlined),
              initialSelection: selectedSubtitle,
              label: Text(AppLocalizations.of(context)!.subtitles),
              dropdownMenuEntries: playerHelper.subtitles
                  .map(
                    (e) => DropdownMenuEntry(
                      leadingIcon: e.deliveryMethod ==
                                  SubtitleDeliveryMethod.external_ ||
                              e.index == -1
                          ? null
                          : const Icon(Icons.done_rounded),
                      enabled: e.deliveryMethod ==
                              SubtitleDeliveryMethod.external_ ||
                          e.index == -1,
                      value: e,
                      labelWidget: Text(
                        e.displayTitle ?? AppLocalizations.of(context)!.none,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      label:
                          e.displayTitle ?? AppLocalizations.of(context)!.none,
                    ),
                  )
                  .toList(),
              onSelected: (value) {
                if (value != null) {
                  selectedSubtitle = value;
                }
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, (null, null));
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
                context, (selectedAudio.index, selectedSubtitle.index));
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
