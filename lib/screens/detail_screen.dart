import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:openapi/openapi.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class DetailScreen extends HookConsumerWidget {
  final String itemId;

  const DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonSelection = useState(0);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
          future: ref.read(apiProvider).getItemDetails(itemId),
          builder: (context, AsyncSnapshot<BaseItemDto> snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: ref
                                        .read(apiProvider)
                                        .getImage(itemId, ImageType.backdrop),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color.fromARGB(100, 0, 0, 0),
                                      Theme.of(context).colorScheme.background
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, left: 8.0, right: 8.0),
                                child: Material(
                                  elevation: 10.0,
                                  child: Container(
                                    width: 150.0,
                                    height: 4 / 3 * 150.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4.0),
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: ref.read(apiProvider).getImage(
                                            itemId, ImageType.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment
                                      .end, // Align text to the bottom
                                  children: [
                                    Text(
                                      snapshot.data!.name!,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      children: [
                                        Text(
                                          snapshot.data!.premiereDate == null
                                              ? 'N/A'
                                              : snapshot
                                                  .data!.premiereDate!.year
                                                  .toString(),
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 0.7,
                                              )),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: Text(
                                              snapshot.data!.officialRating ==
                                                      null
                                                  ? 'N/A'
                                                  : snapshot
                                                      .data!.officialRating!,
                                              style: const TextStyle(
                                                fontSize: 10.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Row(
                                      children: [
                                        snapshot.data!.communityRating == null
                                            ? const SizedBox()
                                            : Row(
                                                children: [
                                                  const Text(
                                                    "⭐",
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                  const SizedBox(width: 4.0),
                                                  Text(
                                                    (snapshot.data!
                                                                .communityRating ==
                                                            null)
                                                        ? 'N/A'
                                                        : snapshot.data!
                                                            .communityRating!
                                                            .roundToDouble()
                                                            .toString(),
                                                    style: const TextStyle(
                                                      fontSize: 12.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        const SizedBox(width: 16.0),
                                        snapshot.data!.criticRating == null
                                            ? const SizedBox()
                                            : Row(
                                                children: [
                                                  const Text(
                                                    "🍅",
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                  const SizedBox(width: 4.0),
                                                  Text(
                                                    snapshot.data!.criticRating!
                                                        .round()
                                                        .toString(),
                                                    style: const TextStyle(
                                                      fontSize: 12.0,
                                                    ),
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
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => PlayerSreen(
                                          url:
                                              'http://192.168.179.21:8096/videos/$itemId/master.m3u8?MediaSourceId=$itemId',
                                          headers:
                                              ref.read(apiProvider).headers,
                                        )),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.0),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Add your watched button logic here
                              },
                              style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  )),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.0),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                // Add your watched button logic here
                              },
                              style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  )),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15.0),
                      child: Text(
                        snapshot.data!.overview ?? 'N/A',
                      ),
                    ),
                    // urls for review sites
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        height: 20,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.externalUrls!.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () async {
                                await launchUrl(Uri.dataFromString(
                                    snapshot.data!.externalUrls![index].url!));
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Text(
                                  snapshot.data!.externalUrls![index].name!,
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Writers',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('Directors',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('Genres',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 20.0),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // find every person that is a writer
                                Text(snapshot.data!.people!
                                        .where((element) =>
                                            element.type == 'Writer')
                                        .isEmpty
                                    ? 'N/A'
                                    : snapshot.data!.people!
                                        .where((element) =>
                                            element.type == 'Writer')
                                        .map((e) => e.name!)
                                        .join(", ")),
                                Text(snapshot.data!.people!
                                        .where((element) =>
                                            element.type == 'Director')
                                        .isEmpty
                                    ? 'N/A'
                                    : snapshot.data!.people!
                                        .where((element) =>
                                            element.type == 'Director')
                                        .map((e) => e.name!)
                                        .join(", ")),
                                Text(
                                  snapshot.data!.genres!.isEmpty
                                      ? "N/A"
                                      : snapshot.data!.genres!.join(", "),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    snapshot.data!.isFolder!
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Text("Episodes",
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall),
                                ),
                                FutureBuilder(
                                  future:
                                      ref.read(apiProvider).getEpisodes(itemId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      var seasons = snapshot.data!.items
                                          .map((e) => e.seasonName)
                                          .toSet()
                                          .toList();

                                      // get season ids
                                      var seasonIds = snapshot.data!.items
                                          .map((e) => e.seasonId)
                                          .toSet()
                                          .toList();
                                      // get episodes for season
                                      var episodes = snapshot.data!.items
                                          .where((element) =>
                                              element.seasonId ==
                                              seasonIds[seasonSelection.value])
                                          .toList();
                                      return Column(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 60,
                                            child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                shrinkWrap: true,
                                                itemCount: seasons.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5.0),
                                                    child: ChoiceChip(
                                                        selected:
                                                            seasonSelection
                                                                    .value ==
                                                                index,
                                                        onSelected: (selected) {
                                                          seasonSelection
                                                              .value = index;
                                                        },
                                                        label: Text(
                                                            seasons[index])),
                                                  );
                                                }),
                                          ),
                                          ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: episodes.length,
                                            itemBuilder: (context, index) {
                                              var item = episodes[index];
                                              return SizedBox(
                                                height: 125,
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PlayerSreen(
                                                          url:
                                                              'http://192.168.179.21:8096/videos/${item.id}/master.m3u8?MediaSourceId=${item.id}',
                                                          headers: ref
                                                              .read(apiProvider)
                                                              .headers,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 20.0),
                                                        child: AspectRatio(
                                                          aspectRatio: 16 / 10,
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10.0),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.5),
                                                                  spreadRadius:
                                                                      2,
                                                                  blurRadius: 5,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 3),
                                                                ),
                                                              ],
                                                              image:
                                                                  DecorationImage(
                                                                fit: BoxFit
                                                                    .cover,
                                                                image: ref
                                                                    .read(
                                                                        apiProvider)
                                                                    .getImage(
                                                                        item
                                                                            .id!,
                                                                        ImageType
                                                                            .primary),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 20.0),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 20.0),
                                                        child: SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.5,
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                ("${item.indexNumber!}. ${item.name!}"),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        16.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                              Text(
                                                                  "${(item.runTimeTicks / 10000000 / 60).round()} min")
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const CircularProgressIndicator();
                                    }
                                  },
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                    snapshot.data!.people!.isEmpty
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            child: ItemCarousel(
                              title: 'Cast',
                              titleList: snapshot.data!.people!
                                  .map((e) => e.name!)
                                  .toList(),
                              imageList: snapshot.data!.people!
                                  .map((e) => e.id!)
                                  .toList(),
                              subtitleList: snapshot.data!.people!
                                  .map((e) => e.role!)
                                  .toList(),
                            ),
                          ),
                  ],
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          }),
    );
  }
}
