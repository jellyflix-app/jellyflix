import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:jellyflix/models/poster_type.dart';
import 'package:jellyflix/providers/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openapi/openapi.dart';

class ItemCarousel extends StatefulHookConsumerWidget {
  final String? title;
  final List titleList;
  final List imageList;
  final List subtitleList;
  final List? blurHashList;
  final List<Widget>? overlay;
  final PosterType posterType;
  final Function(int)? onTap;

  ItemCarousel(
      {this.onTap,
      required this.imageList,
      required this.titleList,
      this.blurHashList,
      this.title,
      this.overlay,
      subtitleList,
      this.posterType = PosterType.vertical,
      super.key})
      : subtitleList = subtitleList ?? [];

  @override
  ConsumerState<ItemCarousel> createState() => _ItemCarouselState();
}

class _ItemCarouselState extends ConsumerState<ItemCarousel> {
  double width = 150;
  double height = 200;

  final ScrollController scrollController = ScrollController();

  var hasClients = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients != hasClients) {
        setState(() {
          hasClients = scrollController.hasClients;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.posterType) {
      case PosterType.horizontal:
        width = 250;
        height = 150;
        break;
      case PosterType.square:
        width = 150;
        height = 150;
        break;
      default:
        width = 150;
        height = 200;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.title == null
            ? const SizedBox()
            : Text(
                widget.title!,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
        const SizedBox(height: 5.0),
        Stack(
          children: [
            SizedBox(
              height: 250,
              child: ListView.builder(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: widget.titleList.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: width,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: width,
                            height: height,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ref.read(apiProvider).getImage(
                                          id: widget.imageList[index],
                                          type: ImageType.primary,
                                          blurHash: widget.blurHashList == null
                                              ? null
                                              : widget.blurHashList![index])),
                                ),
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10.0),
                                      onTap: () {
                                        if (widget.onTap != null) {
                                          widget.onTap!(index);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                widget.overlay != null
                                    ? widget.overlay![index]
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Flexible(
                            child: Text(
                              widget.titleList[index],
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          widget.subtitleList.isNotEmpty
                              ? Text(
                                  widget.subtitleList[index],
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                )
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (hasClients &&
                scrollController.position.maxScrollExtent > 0 &&
                !Platform.isAndroid &&
                !Platform.isIOS)
              Positioned(
                top: 50,
                bottom: 100,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  hoverColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2),
                  onPressed: () {
                    scrollController.animateTo(
                      scrollController.offset - (2 * width),
                      curve: Curves.easeInOut,
                      duration: const Duration(milliseconds: 400),
                    );
                  },
                ),
              ),
            if (scrollController.hasClients &&
                scrollController.position.maxScrollExtent > 0 &&
                !Platform.isAndroid &&
                !Platform.isIOS)
              Positioned(
                top: 50,
                bottom: 100,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  hoverColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2),
                  onPressed: () {
                    scrollController.animateTo(
                      scrollController.offset + (2 * width),
                      curve: Curves.easeInOut,
                      duration: const Duration(milliseconds: 400),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
