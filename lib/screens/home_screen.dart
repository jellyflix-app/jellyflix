import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/carousel_media_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/screens/profile_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen()));
              },
              icon: const Icon(Icons.person_outline_rounded))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Continue carousel
              FutureBuilder(
                  future: ref.read(apiProvider).getContinueWatching(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ItemCarousel(
                          onTap: (index) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                      itemId: snapshot.data!.items[index].id!,
                                    )));
                          },
                          imageList: snapshot.data!.items.map((e) {
                            return e.id!;
                          }).toList(),
                          titleList: snapshot.data!.items.map((e) {
                            return e.name!;
                          }).toList(),
                          title: "Continue Watching");
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
              FutureBuilder(
                  future: ref.read(apiProvider).getLatestItems("movies"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ItemCarousel(
                          onTap: (index) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                      itemId: snapshot.data![index].id!,
                                    )));
                          },
                          imageList: snapshot.data!.map((e) {
                            return e.id!;
                          }).toList(),
                          titleList: snapshot.data!.map((e) {
                            return e.name!;
                          }).toList(),
                          title: "Recently Added Movies",
                          mediaType: CarouselMediaType.vertical);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
              FutureBuilder(
                  future: ref.read(apiProvider).getLatestItems("tvshows"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return ItemCarousel(
                          onTap: (index) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => DetailScreen(
                                      itemId: snapshot.data![index].id!,
                                    )));
                          },
                          imageList: snapshot.data!.map((e) {
                            return e.id!;
                          }).toList(),
                          titleList: snapshot.data!.map((e) {
                            return e.name!;
                          }).toList(),
                          title: "Recently Added Shows",
                          mediaType: CarouselMediaType.vertical);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
