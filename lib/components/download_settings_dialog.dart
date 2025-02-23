import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/services/player_helper.dart';
import 'package:tentacle/tentacle.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DownloadSettingsDialog extends HookConsumerWidget {
  final PlaybackInfoResponse downloadInfo;
  final PlayerHelper playerHelper;

  DownloadSettingsDialog({super.key, required this.downloadInfo})
      : playerHelper = PlayerHelper(playbackInfo: downloadInfo);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MediaStream selectedAudio = playerHelper.getDefaultAudio();
    MediaStream selectedSubtitle = playerHelper.getDefaultSubtitle();

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
          if (playerHelper.subtitles.isNotEmpty)
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
                      enabled:
                          e.deliveryMethod == SubtitleDeliveryMethod.external_,
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
