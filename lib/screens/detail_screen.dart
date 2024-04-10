import 'dart:async';
import 'dart:ui';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:jellyflix/components/jellyfin_image.dart';
import 'package:jellyflix/components/jfx_layout.dart';
import 'package:jellyflix/components/jfx_tile.dart';
import 'package:jellyflix/components/jfx_button_row.dart';
import 'package:openapi/openapi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:jellyflix/components/description_text.dart';
import 'package:jellyflix/components/episode_list.dart';
import 'package:jellyflix/components/item_information_details.dart';
import 'package:jellyflix/models/screen_paths.dart';
import 'package:jellyflix/models/skeleton_item.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/components/future_item_carousel.dart';
import 'package:jellyflix/components/item_carousel.dart';

class DetailScreen extends HookConsumerWidget {
  final String itemId;

  const DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ValueNotifier<bool> onWatchlist = useState(false);
    final ValueNotifier<bool> markedAsPlayed = useState(false);
    final StreamController<List<BaseItemDto>> episodeStreamController =
        useStreamController();
    final playButtonHovered = useState(false);

    final scrollController = useScrollController();
    final appBarColorTransaparent = useState(true);

    useEffect(() {
      listener() {
        if (scrollController.position.pixels > 0) {
          appBarColorTransaparent.value = false;
        } else {
          appBarColorTransaparent.value = true;
        }
      }

      scrollController.addListener(listener);
      return () {
        return scrollController.removeListener(listener);
      };
    }, [scrollController]);

    ref.read(apiProvider).getWatchlist().then((value) {
      onWatchlist.value =
          value.where((element) => element.id == itemId).isNotEmpty;
    });

    final layout = JfxLayout.scalingLayout(context);
    final featuredPosterHeight = layout.tileHeight * 1.3;
    final featuredPosterWidth = layout.tileWidth * 1.3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBarColorTransaparent.value
          ? AppBar(
              backgroundColor: Colors.transparent,
            )
          : PreferredSize(
              preferredSize: const Size(
                double.infinity,
                56.0,
              ),
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: AppBar(
                    elevation: 0.0,
                    backgroundColor: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
            ),
      body: FutureBuilder(
          future: ref.read(apiProvider).getItemDetails(itemId),
          builder: (context, AsyncSnapshot<BaseItemDto> snapshot) {
            BaseItemDto data = SkeletonItem.baseItemDto;
            if (snapshot.hasError) {
              return Center(
                child: Text(
                    AppLocalizations.of(context)!.quickConnectErrorUnknown),
              );
            } else if (snapshot.hasData) {
              data = snapshot.data!;
              if (data.type == BaseItemKind.series) {
                ref.read(apiProvider).getEpisodes(itemId).then((value) {
                  episodeStreamController.add(value);
                });
              }
              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: featuredPosterHeight +
                            MediaQuery.of(context).padding.top,
                        child: Stack(
                          children: [
                            Stack(
                              children: [
                                JellyfinImage(
                                    borderRadius: BorderRadius.zero,
                                    id: data.type == BaseItemKind.episode
                                        ? data.seriesId!
                                        : itemId,
                                    type: ImageType.backdrop,
                                    blurHash: data
                                        .imageBlurHashes?.backdrop?[itemId]),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color.fromARGB(100, 0, 0, 0),
                                        Theme.of(context).colorScheme.surface
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).padding.top,
                                    ),
                                    JfxTile(
                                      id: itemId,
                                      blurHash: data
                                          .imageBlurHashes?.primary?[itemId],
                                      tileWidth: featuredPosterWidth,
                                      tileHeight: featuredPosterHeight,
                                      onTap: () => {},
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment
                                        .end, // Align text to the bottom
                                    children: [
                                      Text(
                                        data.name ?? "",
                                        style:
                                            layout.text.headlineSmall!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          Text(
                                            data.premiereDate == null
                                                ? AppLocalizations.of(context)!
                                                    .na
                                                : data.premiereDate!.year
                                                    .toString(),
                                            style: layout.text.bodyLarge,
                                          ),
                                          const SizedBox(width: 16.0),
                                          Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 0.7,
                                                )),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(3.0),
                                              child: Text(
                                                data.officialRating ??
                                                    AppLocalizations.of(
                                                            context)!
                                                        .na,
                                                style: layout.text.bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          data.communityRating == null
                                              ? const SizedBox()
                                              : Row(
                                                  children: [
                                                    const Text(
                                                      "⭐",
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      (data.communityRating ==
                                                              null)
                                                          ? AppLocalizations.of(
                                                                  context)!
                                                              .na
                                                          : data
                                                              .communityRating!
                                                              .roundToDouble()
                                                              .toString(),
                                                      style:
                                                          layout.text.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                          const SizedBox(width: 16.0),
                                          data.criticRating == null
                                              ? const SizedBox()
                                              : Row(
                                                  children: [
                                                    const Text(
                                                      "🍅",
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    const SizedBox(width: 4.0),
                                                    Text(
                                                      data.criticRating!
                                                          .round()
                                                          .toString(),
                                                      style:
                                                          layout.text.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 15.0),
                        child: CustomButtonRow(
                          context: context,
                          ref: ref,
                          data: data,
                          itemId: itemId,
                          addtlVersionsHovered: playButtonHovered,
                          playButtonHovered: playButtonHovered,
                          onWatchlist: onWatchlist,
                          markedAsPlayed: markedAsPlayed,
                          streamController: episodeStreamController,
                          goToPlayerScreen: goToPlayerScreen,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 15.0),
                        child: DescriptionText(
                          text:
                              data.overview ?? AppLocalizations.of(context)!.na,
                        ),
                      ),

                      data.isFolder ?? false
                          ? EpisodeList(
                              episodeStreamController: episodeStreamController,
                              data: data,
                              markedAsPlayed: markedAsPlayed,
                              itemId: itemId)
                          : const SizedBox(),
                      data.people != null && data.people!.isNotEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15.0),
                              child: ItemCarousel(
                                title: AppLocalizations.of(context)!.cast,
                                titleList:
                                    data.people!.map((e) => e.name!).toList(),
                                imageList:
                                    data.people!.map((e) => e.id!).toList(),
                                subtitleList: data.people!
                                    .map((e) =>
                                        e.role ??
                                        AppLocalizations.of(context)!.na)
                                    .toList(),
                                onTap: (index) {
                                  context.push(Uri(
                                      path: ScreenPaths.detail,
                                      queryParameters: {
                                        "id": data.people![index].id!,
                                      }).toString());
                                },
                              ),
                            )
                          : const SizedBox(),
                      FutureItemCarousel(
                        future: ref.read(apiProvider).similarItems(itemId),
                        title: AppLocalizations.of(context)!.similar,
                        titleMapping: (e) => e.name!,
                        imageMapping: (e) => e.id!,
                        subtitleMapping: (e) => e.productionYear.toString(),
                        blurHashMapping: (e) =>
                            e.imageBlurHashes?.primary?[e.id!],
                        onTap: (index, id) {
                          context.push(
                              Uri(path: ScreenPaths.detail, queryParameters: {
                            "id": id,
                          }).toString());
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10),
                        child: Text(AppLocalizations.of(context)!.details,
                            style: layout.text.headlineSmall),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ItemInformationDetails(item: data),
                      ),
                      // urls for review sites
                      if (data.externalUrls != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: SizedBox(
                            height: layout.text.bodyLarge!.height! * 20,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.externalUrls!.length,
                              itemBuilder: (context, index) {
                                return InkWell(
                                  onTap: () async {
                                    await launchUrl(Uri.parse(
                                        data.externalUrls![index].url!));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 5.0),
                                    child: Text(
                                      data.externalUrls![index].name!,
                                      style: layout.text.bodyLarge!.copyWith(
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  Future<void> goToPlayerScreen(WidgetRef ref, String itemId,
      int playbackStartTicks, BuildContext context) async {
    var playbackInfo = await ref.read(apiProvider).getStreamUrlAndPlaybackInfo(
        itemId: itemId, startTimeTicks: playbackStartTicks);
    if (context.mounted) {
      context.push(
          Uri(path: ScreenPaths.player, queryParameters: {
            "startTimeTicks": playbackStartTicks.toString()
          }).toString(),
          extra: playbackInfo);
    }
  }
}
