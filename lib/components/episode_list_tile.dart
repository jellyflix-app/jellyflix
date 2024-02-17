import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/item_list_tile.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';

class EpisodeListTile extends HookConsumerWidget {
  const EpisodeListTile(
      {super.key, required this.episode, required this.onSelected});

  final BaseItemDto episode;
  final Function(String) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool?> mark = useState(null);

    mark.value = episode.userData!.played!;

    return ItemListTile<BaseItemDto, String>(
      item: episode,
      title: Text(
        ("${episode.indexNumber == null ? "" : "${episode.indexNumber!}. "}${episode.name!}"),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(episode.runTimeTicks == null
          ? AppLocalizations.of(context)!.na
          : "${(episode.runTimeTicks! / 10000000 / 60).round()} min"),
      leading: ref.read(apiProvider).getImage(
          id: episode.id!,
          type: ImageType.primary,
          blurHash: episode.imageBlurHashes?.primary?[episode.id!]),
      onTap: () async {
        var playbackInfo = await ref
            .read(apiProvider)
            .getStreamUrlAndPlaybackInfo(itemId: episode.id!);
        if (context.mounted) {
          context.push(
              Uri(path: ScreenPaths.player, queryParameters: {
                "startTimeTicks":
                    episode.userData?.playbackPositionTicks?.toString()
              }).toString(),
              extra: playbackInfo);
        }
      },
      onSelectedMenuItem: onSelected,
      popupMenuEntries: [
        PopupMenuItem<String>(
          value: 'mark_as_played',
          child: !mark.value!
              ? ListTile(
                  leading: const Icon(Icons.check),
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: Text(
                    AppLocalizations.of(context)!.markAsPlayed,
                  ),
                )
              : ListTile(
                  leading: const Icon(Icons.close),
                  iconColor: Theme.of(context).colorScheme.tertiary,
                  title: Text(
                    AppLocalizations.of(context)!.markAsUnplayed,
                  ),
                ),
        ),
      ],
      overlay: episode.userData!.playedPercentage != null
          ? PlaybackProgressOverlay(
              progress: (episode.userData!.playedPercentage! / 100))
          : mark.value == true
              ? Positioned(
                  bottom: 5.0,
                  right: 5.0,
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: Colors.white.withOpacity(0.8),
                  ),
                )
              : const SizedBox.shrink(),
    );
  }
}
