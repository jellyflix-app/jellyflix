import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/components/episode_list_tile.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:openapi/openapi.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EpisodeList extends HookConsumerWidget {
  const EpisodeList({
    super.key,
    required this.data,
    required this.markedAsPlayed,
    required this.itemId,
    required this.episodeStreamController,
  });

  final BaseItemDto data;
  final ValueNotifier<bool?> markedAsPlayed;
  final String itemId;
  final StreamController<List<BaseItemDto>> episodeStreamController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonSelection = useState(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          child: Text(AppLocalizations.of(context)!.episodes,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        StreamBuilder(
          stream: episodeStreamController.stream,
          builder: (context, snapshot) {
            var seasons = [];
            var seasonIds = [];
            var episodes = [];
            if (snapshot.hasData) {
              seasons =
                  snapshot.data!.map((e) => e.seasonName).toSet().toList();

              // get season ids
              seasonIds =
                  snapshot.data!.map((e) => e.seasonId).toSet().toList();
              // get episodes for season
              episodes = snapshot.data!
                  .where((element) =>
                      element.seasonId == seasonIds[seasonSelection.value])
                  .toList();
            }
            return Skeletonizer(
              enabled: !snapshot.hasData,
              child: Column(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 60,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemCount: seasons.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: ChoiceChip(
                                selected: seasonSelection.value == index,
                                onSelected: (selected) {
                                  seasonSelection.value = index;
                                },
                                label: Text(seasons[index])),
                          );
                        }),
                  ),
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      BaseItemDto item = episodes[index];

                      return EpisodeListTile(
                        item: item,
                        data: data,
                        onSelected: (value) async {
                          if (value == 'mark_as_played') {
                            await ref.read(apiProvider).markAsPlayed(
                                itemId: item.id!,
                                played: !item.userData!.played!);
                            if (markedAsPlayed.value == true &&
                                item.userData!.played!) {
                              markedAsPlayed.value = false;
                            } else if (markedAsPlayed.value == false &&
                                episodes
                                        .where((element) =>
                                            element.userData!.played == false)
                                        .length ==
                                    1 &&
                                !item.userData!.played!) {
                              markedAsPlayed.value = true;
                            }

                            episodeStreamController.add(await ref
                                .read(apiProvider)
                                .getEpisodes(itemId));
                          }
                        },
                      );
                    },
                  )
                ],
              ),
            );
            // } else {
            //   return const CircularProgressIndicator();
            // }
          },
        ),
      ],
    );
  }
}
