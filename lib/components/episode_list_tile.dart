import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/playback_progress_overlay.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:tentacle/tentacle.dart';

class EpisodeListTile extends HookConsumerWidget {
  const EpisodeListTile(
      {super.key,
      required this.item,
      required this.data,
      required this.onSelected});

  final BaseItemDto item;
  final BaseItemDto data;
  final Function(String) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool?> mark = useState(null);

    mark.value = item.userData!.played!;

    return SizedBox(
      height: 125,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () async {
          var playbackInfo = await ref
              .read(apiProvider)
              .getStreamUrlAndPlaybackInfo(itemId: item.id!);
          if (context.mounted) {
            context.push(
                Uri(path: ScreenPaths.player, queryParameters: {
                  "startTimeTicks":
                      data.userData?.playbackPositionTicks?.toString()
                }).toString(),
                extra: playbackInfo);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ref.read(apiProvider).getImage(
                            id: item.id!,
                            type: ImageType.primary,
                            blurHash: item.imageBlurHashes?.primary?[item.id!]),
                      ),
                      if (item.userData!.playedPercentage != null)
                        PlaybackProgressOverlay(
                            progress: (item.userData!.playedPercentage! / 100)),
                      if (mark.value == true)
                        Positioned(
                          bottom: 5.0,
                          right: 5.0,
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20.0),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ("${item.indexNumber == null ? "" : "${item.indexNumber!}. "}${item.name!}"),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      Text(item.runTimeTicks == null
                          ? AppLocalizations.of(context)!.na
                          : "${(item.runTimeTicks! / 10000000 / 60).round()} min")
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomCenter,
                child: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
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
                  onSelected: onSelected,
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
