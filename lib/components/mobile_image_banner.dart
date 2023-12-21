import 'dart:async';

import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:jellyflix/screens/detail_screen.dart';
import 'package:jellyflix/screens/player_screen.dart';
import 'package:openapi/openapi.dart';

class MobileImageBanner extends StatefulHookConsumerWidget {
  final List<BaseItemDto> items;
  final Duration scrollDuration;
  final double? height;

  const MobileImageBanner(
      {super.key,
      required this.items,
      this.height = 600,
      this.scrollDuration = const Duration(seconds: 5)});

  @override
  MobileImageBannerState createState() => MobileImageBannerState();
}

class MobileImageBannerState extends ConsumerState<MobileImageBanner> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.scrollDuration, (timer) {
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _controller.animateToPage(_currentPage,
          duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.bottomCenter,
      children: [
        Container(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemBuilder: (context, index) {
              // check if backdrop exists else use primary image

              return Stack(children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: ref.read(apiProvider).getImage(
                          widget.items[index].id!,
                          widget.items[index].backdropImageTags!.isNotEmpty
                              ? ImageType.backdrop
                              : ImageType.primary),
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
                        Color.fromARGB(30, 0, 0, 0),
                        Theme.of(context).colorScheme.background
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 40),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.items[index].name!,
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 2,
                        ),
                        Text(widget.items[index].productionYear.toString(),
                            style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PlayerSreen(
                                        itemId: widget.items[index].id!,
                                        headers: ref.read(apiProvider).headers),
                                  ),
                                );
                              },
                              label: Text("Play"),
                              icon: Icon(Icons.play_arrow_rounded),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        itemId: widget.items[index].id!,
                                      ),
                                    ),
                                  );
                                },
                                child: Text("More Info")),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: DotsIndicator(
            dotsCount: widget.items.length,
            position: _currentPage,
            decorator: DotsDecorator(
              activeColor: Theme.of(context).buttonTheme.colorScheme!.primary,
              activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
              activeSize: const Size(40.0, 7.0),
              size: const Size(20, 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0)),
            ),
            onTap: (position) {
              _controller.animateToPage(position,
                  duration: Duration(milliseconds: 350), curve: Curves.easeIn);
            },
          ),
        ),
      ],
    );
  }
}
