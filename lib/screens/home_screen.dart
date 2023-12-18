import 'package:jellyflix/components/item_carousel.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/screens/library_screen.dart';
import 'package:jellyflix/screens/profile_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LibraryScreen()));
          },
          icon: const Icon(Icons.video_library_outlined),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const ProfileScreen()));
              },
              icon: const Icon(Icons.person_outline_rounded))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.blueGrey,
              child: const Text("Header"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                //mainAxisSize: MainAxisSize.min,
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
                                          itemId:
                                              snapshot.data!.items[index].id!,
                                        )));
                              },
                              imageList: snapshot.data!.items.map((e) {
                                return e.id!;
                              }).toList(),
                              titleList: snapshot.data!.items.map((e) {
                                return e.name!;
                              }).toList(),
                              subtitleList: snapshot.data!.items.map((e) {
                                return e.productionYear.toString();
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
                              subtitleList: snapshot.data!.map((e) {
                                return e.productionYear.toString();
                              }).toList(),
                              posterType: PosterType.vertical);
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
                              subtitleList: snapshot.data!.map((e) {
                                return e.productionYear.toString();
                              }).toList(),
                              title: "Recently Added Shows",
                              posterType: PosterType.vertical);
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
