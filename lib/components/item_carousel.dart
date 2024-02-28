import 'package:flutter/scheduler.dart';
import 'package:jellyflix/components/item_carousel_row.dart';
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
  final Function? onEnd;
  final ScrollController? scrollController;

  ItemCarousel(
      {this.onTap,
      required this.imageList,
      required this.titleList,
      this.blurHashList,
      this.title,
      this.overlay,
      subtitleList,
      this.onEnd,
      this.posterType = PosterType.vertical,
      this.scrollController,
      super.key})
      : subtitleList = subtitleList ?? [];

  @override
  ConsumerState<ItemCarousel> createState() => _ItemCarouselState();
}

class _ItemCarouselState extends ConsumerState<ItemCarousel> {
  double width = 150;
  double height = 200;

  late final ScrollController scrollController;

  var hasClients = false;
  var isLoading = false;
  ValueNotifier<bool> showArrows = ValueNotifier(false);
  @override
  void initState() {
    super.initState();
    scrollController = widget.scrollController ?? ScrollController();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients != hasClients) {
        setState(() {
          hasClients = scrollController.hasClients;
        });
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent * 0.7 <=
          scrollController.position.pixels) {
        if (widget.onEnd != null) {
          widget.onEnd!();
        }
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ItemCarouselRow(
              title: widget.title,
              scrollController: scrollController,
              offsetWidth: (3 * width)),
        ),
        const SizedBox(height: 5.0),
        SizedBox(
          height: 250,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: widget.titleList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                    left: index == 0 ? 10.0 : 0.0,
                    right: index == widget.titleList.length - 1 ? 10.0 : 0.0),
                child: SizedBox(
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
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
